# frozen_string_literal: true

class VideoProcessingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 10.seconds, attempts: 3

  sidekiq_options unique: :until_executed, lock_ttl: 2.hour

  def perform(upload_id)
    upload = Upload.find(upload_id)
    return if upload.status == 'success'

    update_upload_progress(upload, 10, 'processing')

    begin
      temp_file_path = extract_temp_file_path(upload)
      raise "Temporary file not found: #{temp_file_path}" unless temp_file_path.present? && File.exist?(temp_file_path)

      temp_dirs = setup_temp_directories(upload.id.to_s)
      formats = []
      update_upload_progress(upload, 20)

      mp4_path = convert_to_mp4(temp_file_path, temp_dirs[:videos_dir])
      formats << 'mp4'
      update_upload_progress(upload, 40)

      create_thumbnail(mp4_path, temp_dirs[:thumbnail_dir])
      update_upload_progress(upload, 50)

      hls_result = convert_to_hls(mp4_path, temp_dirs[:hls_dir])
      formats << 'hls' if hls_result[:success]
      update_upload_progress(upload, 80)

      video_info = extract_video_info(mp4_path)

      s3_paths = upload_to_s3(upload.id.to_s, temp_dirs, formats)

      update_upload_progress(upload, 100, 'success', {
                               cdn_url: s3_paths[:hls_url] || s3_paths[:mp4_url],
                               thumbnail_path: s3_paths[:thumbnail_url],
                               formats: formats,
                               duration: video_info[:duration].to_i,
                               quality_360p_url: s3_paths[:quality_360p_url],
                               quality_480p_url: s3_paths[:quality_480p_url],
                               quality_720p_url: s3_paths[:quality_720p_url]
                             })

      cleanup_temp_files(temp_dirs.values, temp_file_path)

      Rails.logger.info "Xử lý video hoàn tất: #{s3_paths[:hls_url] || s3_paths[:mp4_url]}"
    rescue StandardError => e
      handle_error(upload, e, temp_file_path)
      raise e
    end
  end

  private

  def extract_temp_file_path(upload)
    upload.processing_log.to_s.split("\n").first
  rescue StandardError
    nil
  end

  def setup_temp_directories(upload_id)
    dirs = {
      videos_dir: Rails.root.join('tmp', 'video_processing', upload_id, 'videos'),
      hls_dir: Rails.root.join('tmp', 'video_processing', upload_id, 'hls'),
      thumbnail_dir: Rails.root.join('tmp', 'video_processing', upload_id, 'thumbnails')
    }

    dirs.each_value do |dir|
      FileUtils.mkdir_p(dir)
      FileUtils.chmod(0o755, dir)
    end

    dirs
  end

  def convert_to_mp4(temp_file_path, videos_dir)
    mp4_path = File.join(videos_dir, 'video.mp4')

    convert_cmd = "ffmpeg -y -i #{temp_file_path} -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k #{mp4_path}"
    system(convert_cmd)

    unless File.exist?(mp4_path) && File.size?(mp4_path).to_i.positive?
      Rails.logger.warn 'Không thể chuyển đổi video sang MP4, thử phương pháp copy trực tiếp'
      FileUtils.cp(temp_file_path, mp4_path)
    end

    FileUtils.chmod(0o644, mp4_path)
    mp4_path
  end

  def create_thumbnail(mp4_path, thumbnail_dir)
    thumbnail_path = File.join(thumbnail_dir, 'thumbnail.jpg')

    begin
      duration_seconds = get_video_duration(mp4_path)
      thumbnail_position = determine_thumbnail_position(duration_seconds)
      position_formatted = Time.at(thumbnail_position).utc.strftime('%H:%M:%S')

      Rails.logger.info "Trích xuất thumbnail tại vị trí: #{position_formatted} (#{thumbnail_position}s)"

      thumbnail_cmd = "ffmpeg -y -i #{mp4_path} -ss #{position_formatted} -vframes 1 -f image2 #{thumbnail_path}"
      system(thumbnail_cmd)
    rescue StandardError => e
      Rails.logger.error "Lỗi khi tạo thumbnail: #{e.message}"
      simple_thumbnail_cmd = "ffmpeg -y -i #{mp4_path} -ss 00:00:03 -vframes 1 -f image2 #{thumbnail_path}"
      system(simple_thumbnail_cmd)
    end

    create_empty_thumbnail_if_needed(thumbnail_path)
    FileUtils.chmod(0o644, thumbnail_path)
    Rails.logger.info "Đã tạo thumbnail tại: #{thumbnail_path}"
    thumbnail_path
  end

  def get_video_duration(mp4_path)
    duration_cmd = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{mp4_path}"
    `#{duration_cmd}`.strip.to_f
  end

  def determine_thumbnail_position(duration_seconds)
    if duration_seconds.positive?
      [10, duration_seconds / 2].min
    else
      3
    end
  end

  def create_empty_thumbnail_if_needed(thumbnail_path)
    unless File.exist?(thumbnail_path) && File.size(thumbnail_path).positive?
      File.open(thumbnail_path, 'w') { |f| f.write('') }
    end
  end

  def convert_to_hls(mp4_path, hls_dir)
    result = {
      success: false,
      quality_dirs: {
        '360p' => nil,
        '480p' => nil,
        '720p' => nil
      }
    }

    begin
      master_m3u8_path = File.join(hls_dir, 'master.m3u8')
      qualities = define_hls_qualities

      prepare_hls_directories(hls_dir, qualities)
      Rails.logger.info "Bắt đầu chuyển đổi HLS cho file: #{mp4_path}"

      master_content = "#EXTM3U\n#EXT-X-VERSION:3\n"
      hls_success = false

      qualities.each do |quality, options|
        quality_result = convert_quality(mp4_path, hls_dir, quality, options)

        next unless quality_result[:success]

        master_content += quality_result[:master_content]
        result[:quality_dirs][quality] = quality_result[:dir]
        hls_success = true
      end

      if hls_success
        File.write(master_m3u8_path, master_content)
        FileUtils.chmod(0o644, master_m3u8_path)
        result[:success] = true
        result[:master_path] = master_m3u8_path
        Rails.logger.info 'Tạo master playlist HLS thành công'
      else
        Rails.logger.warn 'Không thể tạo master playlist HLS'
      end
    rescue StandardError => e
      Rails.logger.error "Lỗi khi chuyển đổi HLS: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    result
  end

  def define_hls_qualities
    {
      '360p' => { height: 360, bitrate: '800k' },
      '480p' => { height: 480, bitrate: '1400k' },
      '720p' => { height: 720, bitrate: '2800k' }
    }
  end

  def prepare_hls_directories(hls_dir, qualities)
    FileUtils.rm_f(Dir.glob("#{hls_dir}/*.m3u8"))
    FileUtils.rm_f(Dir.glob("#{hls_dir}/*.ts"))

    qualities.each_key do |quality|
      quality_dir = File.join(hls_dir, quality)
      FileUtils.mkdir_p(quality_dir)
      FileUtils.rm_f(Dir.glob("#{quality_dir}/*"))
    end
  end

  def convert_quality(mp4_path, hls_dir, quality, options)
    result = { success: false, master_content: '', dir: nil }

    quality_dir = File.join(hls_dir, quality)
    playlist_m3u8_path = File.join(quality_dir, 'playlist.m3u8')
    segments_path = File.join(quality_dir, 'segment_%03d.ts')

    width = -2
    height = options[:height]
    bitrate = options[:bitrate]

    ffmpeg_cmd = build_ffmpeg_command(mp4_path, width, height, bitrate, segments_path, playlist_m3u8_path)
    Rails.logger.info "Tạo HLS #{quality} với lệnh: #{ffmpeg_cmd}"
    system(ffmpeg_cmd)

    if File.exist?(playlist_m3u8_path)
      bandwidth = get_bandwidth_for_quality(quality)

      result[:master_content] =
        "#EXT-X-STREAM-INF:BANDWIDTH=#{bandwidth},RESOLUTION=#{width != -2 ? width : 'auto'}x#{height}\n"
      result[:master_content] += "#{quality}/playlist.m3u8\n"

      FileUtils.chmod(0o644, playlist_m3u8_path)
      FileUtils.chmod(0o644, Dir.glob("#{quality_dir}/*.ts"))

      result[:dir] = quality_dir
      result[:success] = true

      Rails.logger.info "Chuyển đổi HLS #{quality} thành công"
    else
      Rails.logger.warn "Không thể tạo HLS playlist cho #{quality}"
    end

    result
  end

  # bitrate: Số lượng dữ liệu truyền trong mỗi giây video
  # width, height: chiều rộng, chiều cao của video  ảnh hưởng độ phân giải Độ phân giải
  # segments_path: Giúp người dùng xem video ngay lập tức mà không cần tải toàn bộ file.
  # bandwidth: Tốc độ truyền tải tối đa của video
  # duration : Thời gian video
  # resolution: Độ phân giải video
  # playlist_path: Danh sách các file video nhỏ hơn
  # ffmpeg_cmd: Lệnh ffmpeg để chuyển đổi video
  # ffmpeg: Phần mềm mã nguồn mở để xử lý video
  def build_ffmpeg_command(mp4_path, width, height, bitrate, segments_path, playlist_path)
    "ffmpeg -y -i #{mp4_path} " \
    "-vf scale=#{width}:#{height} " \
    '-c:v libx264 -preset fast -crf 23 ' \
    "-b:v #{bitrate} " \
    '-c:a aac -ar 48000 -b:a 128k -ac 2 ' \
    '-profile:v main -level 3.1 ' \
    '-hls_time 6 ' \
    '-hls_list_size 0 ' \
    '-hls_segment_type mpegts ' \
    '-hls_flags independent_segments ' \
    '-hls_playlist_type vod ' \
    "-hls_segment_filename \"#{segments_path}\" \"#{playlist_path}\""
  end

  def get_bandwidth_for_quality(quality)
    case quality
    when '360p' then 800_000
    when '480p' then 1_400_000
    when '720p' then 2_800_000
    else 1_400_000
    end
  end

  def extract_video_info(mp4_path)
    duration_seconds = get_video_duration(mp4_path)

    resolution_cmd = "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 #{mp4_path}"
    resolution = `#{resolution_cmd}`.strip

    Rails.logger.info "Thông tin video: Thời lượng = #{duration_seconds}s, Độ phân giải = #{resolution}"

    { duration: duration_seconds, resolution: resolution }
  rescue StandardError => e
    Rails.logger.error "Lỗi khi lấy thông tin video: #{e.message}"
    { duration: 0, resolution: '0x0' }
  end

  def upload_to_s3(upload_id, temp_dirs, formats)
    s3_config = YAML.safe_load(ERB.new(File.read(Rails.root.join('config', 'storage.yml'))).result)['amazon']

    raise 'Cấu hình S3 không hợp lệ' if s3_config.nil? || s3_config['access_key_id'].blank?

    s3_client = Aws::S3::Resource.new(
      region: s3_config['region'],
      access_key_id: s3_config['access_key_id'],
      secret_access_key: s3_config['secret_access_key']
    )

    bucket = s3_client.bucket(s3_config['bucket'])

    bucket.objects.limit(1).collect

    base_s3_path = "uploads/#{upload_id}"

    result = {
      mp4_url: nil,
      hls_url: nil,
      thumbnail_url: nil,
      quality_360p_url: nil,
      quality_480p_url: nil,
      quality_720p_url: nil
    }

    mp4_file = File.join(temp_dirs[:videos_dir], 'video.mp4')
    if File.exist?(mp4_file)
      mp4_key = "#{base_s3_path}/video.mp4"
      bucket.object(mp4_key).upload_file(mp4_file)
      result[:mp4_url] = "https://#{bucket.name}.s3.#{s3_client.client.config.region}.amazonaws.com/#{mp4_key}"
    end

    thumbnail_file = File.join(temp_dirs[:thumbnail_dir], 'thumbnail.jpg')
    if File.exist?(thumbnail_file)
      thumbnail_key = "#{base_s3_path}/thumbnail.jpg"
      bucket.object(thumbnail_key).upload_file(thumbnail_file)
      result[:thumbnail_url] = "https://#{bucket.name}.s3.#{s3_client.client.config.region}.amazonaws.com/#{thumbnail_key}"
    end

    if formats.include?('hls')
      master_file = File.join(temp_dirs[:hls_dir], 'master.m3u8')
      if File.exist?(master_file)
        master_key = "#{base_s3_path}/hls/master.m3u8"
        bucket.object(master_key).upload_file(master_file, {
                                                content_type: 'application/x-mpegURL'
                                              })
        result[:hls_url] = "https://#{bucket.name}.s3.#{s3_client.client.config.region}.amazonaws.com/#{master_key}"
      end

      %w[360p 480p 720p].each do |quality|
        quality_dir = File.join(temp_dirs[:hls_dir], quality)
        next unless Dir.exist?(quality_dir)

        playlist_file = File.join(quality_dir, 'playlist.m3u8')
        if File.exist?(playlist_file)
          playlist_key = "#{base_s3_path}/hls/#{quality}/playlist.m3u8"
          bucket.object(playlist_key).upload_file(playlist_file, {
                                                    content_type: 'application/x-mpegURL'
                                                  })
          result[:"quality_#{quality}_url"] = "https://#{bucket.name}.s3.#{s3_client.client.config.region}.amazonaws.com/#{playlist_key}"
        end

        segment_files = Dir.glob(File.join(quality_dir, '*.ts'))
        segment_files.each do |segment_file|
          segment_name = File.basename(segment_file)
          segment_key = "#{base_s3_path}/hls/#{quality}/#{segment_name}"
          bucket.object(segment_key).upload_file(segment_file, {
                                                   content_type: 'video/MP2T'
                                                 })
        end
      end
    end

    result
  rescue StandardError => e
    Rails.logger.error "Lỗi S3: #{e.message}"

    {
      mp4_url: 'https://via.placeholder.com/640x360.png?text=Video+Processing+Failed',
      hls_url: nil,
      thumbnail_url: 'https://via.placeholder.com/640x360.png?text=Thumbnail+Processing+Failed',
      quality_360p_url: nil,
      quality_480p_url: nil,
      quality_720p_url: nil
    }
  end

  def cleanup_temp_files(temp_dirs, original_temp_file = nil)
    File.delete(original_temp_file) if original_temp_file && File.exist?(original_temp_file)

    temp_dirs.each do |dir|
      FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
    end
  end

  def handle_error(upload, error, temp_file_path)
    error_log = "Error processing video: #{error.message}\n#{error.backtrace.join("\n")}"
    error_log = "#{temp_file_path}\n#{error_log}" if temp_file_path.present?

    update_upload_progress(upload, 0, 'failed', { processing_log: error_log })

    Rails.logger.error "Video processing failed for upload ##{upload.id}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n")
  end

  def update_upload_progress(upload, progress, status = nil, additional_attrs = {})
    attrs = { progress: progress }
    attrs[:status] = status if status.present?

    if status == 'success'
      additional_attrs[:cdn_url] = additional_attrs[:cdn_url].presence
      additional_attrs[:thumbnail_path] = additional_attrs[:thumbnail_path].presence
    end

    attrs.merge!(additional_attrs) if additional_attrs.present?

    Rails.logger.info "Cập nhật tiến trình xử lý video #{upload.id}: #{progress}% - #{status || 'đang tiếp tục'}"
    result = upload.update(attrs)

    unless result
      Rails.logger.error "Không thể cập nhật tiến trình cho upload #{upload.id}: #{upload.errors.full_messages.join(', ')}"
    end

    result
  end
end
