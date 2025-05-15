# frozen_string_literal: true

class TranscribeJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 10.seconds, attempts: 3
  sidekiq_options unique: :until_executed, lock_ttl: 2.hours

  def perform(upload_id)
    upload = Upload.find_by(id: upload_id)
    return unless upload
    return if upload.transcription.present?

    update_transcription_status(upload, 'processing')

    begin
      s3_config = load_s3_config
      transcribe_client = initialize_transcribe_client(s3_config)

      video_url = select_video_url(upload)
      return if video_url.blank?

      job_name = "transcribe-#{upload.id}-#{Time.now.to_i}"
      output_path = "uploads/#{upload.id}/transcription"

      start_transcription_job(transcribe_client, job_name, video_url, output_path, s3_config)

      wait_for_completion(transcribe_client, job_name, upload)

      transcription_url = build_transcription_url(s3_config, output_path)
      transcription_text = fetch_transcription(transcription_url)

      if transcription_text.present?
        update_transcription_status(upload, 'completed', transcription_text)
      else
        update_transcription_status(upload, 'failed')
      end

    rescue StandardError => e
      handle_error(upload, e)
    end
  end

  private

  def load_s3_config
    s3_config = YAML.safe_load(ERB.new(File.read(Rails.root.join('config', 'storage.yml'))).result)['amazon']
    raise 'Cấu hình S3 không hợp lệ' if s3_config.nil? || s3_config['access_key_id'].blank?
    s3_config
  end

  def initialize_transcribe_client(s3_config)
    Aws::TranscribeService::Client.new(
      region: s3_config['region'],
      access_key_id: s3_config['access_key_id'],
      secret_access_key: s3_config['secret_access_key']
    )
  end

  def select_video_url(upload)
    return upload.cdn_url if upload.cdn_url.present? &&
                            !upload.cdn_url.include?('placeholder') &&
                            upload.cdn_url.end_with?('.mp4')

    mp4_url_from_log = extract_mp4_url_from_log(upload)
    return mp4_url_from_log if mp4_url_from_log.present?

    Rails.logger.warn "Không tìm thấy MP4 URL cho upload #{upload.id}, AWS Transcribe có thể sẽ thất bại"

    if upload.cdn_url.present? && !upload.cdn_url.include?('placeholder')
      upload.cdn_url
    elsif upload.quality_480p_url.present?
      upload.quality_480p_url
    elsif upload.quality_360p_url.present?
      upload.quality_360p_url
    elsif upload.quality_720p_url.present?
      upload.quality_720p_url
    else
      nil
    end
  end

  def extract_mp4_url_from_log(upload)
    return nil unless upload.processing_log.present?

    log_lines = upload.processing_log.to_s.split("\n")
    mp4_line = log_lines.find { |line| line.include?('/video.mp4') && line.include?('amazonaws.com') }

    if mp4_line.present?
      mp4_line.match(/https:\/\/.*\.mp4/).to_s
    else
      bucket = load_s3_config['bucket']
      region = load_s3_config['region']
      "https://#{bucket}.s3.#{region}.amazonaws.com/uploads/#{upload.id}/video.mp4"
    end
  end

  def start_transcription_job(client, job_name, video_url, output_path, s3_config)
    language_code = 'vi-VN'

    Rails.logger.info "Bắt đầu transcribe job với URL: #{video_url}"

    client.start_transcription_job({
      transcription_job_name: job_name,
      media: { media_file_uri: video_url },
      language_code: language_code,
      output_bucket_name: s3_config['bucket'],
      output_key: "#{output_path}/transcript.json",
      settings: {
        show_speaker_labels: true,
        max_speaker_labels: 2,
        show_alternatives: false
      }
    })

    Rails.logger.info "Đã bắt đầu transcribe job: #{job_name} cho video: #{video_url}"
  end

  def wait_for_completion(client, job_name, upload)
    max_attempts = 60
    attempts = 0

    loop do
      response = client.get_transcription_job(transcription_job_name: job_name)
      status = response.transcription_job.transcription_job_status

      case status
      when 'COMPLETED'
        Rails.logger.info "Transcribe job #{job_name} đã hoàn thành"
        break
      when 'FAILED'
        error_message = response.transcription_job.failure_reason || 'Không rõ lỗi'
        Rails.logger.error "Transcribe job #{job_name} thất bại: #{error_message}"
        update_transcription_status(upload, 'failed')
        raise "Transcribe job failed: #{error_message}"
      when 'IN_PROGRESS'
        Rails.logger.info "Transcribe job #{job_name} đang xử lý... (#{attempts}/#{max_attempts})"
      end

      attempts += 1
      if attempts >= max_attempts
        update_transcription_status(upload, 'failed')
        raise "Timeout waiting for transcription job to complete"
      end

      sleep 30
    end
  end

  def build_transcription_url(s3_config, output_path)
    bucket = s3_config['bucket']
    region = s3_config['region']
    "https://#{bucket}.s3.#{region}.amazonaws.com/#{output_path}/transcript.json"
  end

  def fetch_transcription(transcription_url)
    response = Faraday.get(transcription_url)

    if response.status == 200
      data = JSON.parse(response.body)

      if data['results'] && data['results']['transcripts']
        data['results']['transcripts'].map { |t| t['transcript'] }.join(' ')
      end
    end
  end

  def update_transcription_status(upload, status, transcription_text = nil)
    attributes = { transcription_status: status }
    attributes[:transcription] = transcription_text if transcription_text.present?

    upload.update(attributes)
  end

  def handle_error(upload, error)
    Rails.logger.error "Error during transcription: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")

    update_transcription_status(upload, 'failed')
  end
end
