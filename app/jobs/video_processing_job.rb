# frozen_string_literal: true

begin
  require 'streamio-ffmpeg'
rescue LoadError
  puts 'Gem streamio-ffmpeg chưa được cài đặt. Một số tính năng xử lý video sẽ không khả dụng.'
end
require 'fileutils'

class VideoProcessingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  sidekiq_options unique: :until_executed, lock_ttl: 1.hour

  def perform(upload_id)
    upload = Upload.find(upload_id)
    return if upload.status == 'success'

    update_upload_progress(upload, 10, 'processing')

    begin
      temp_file_path = extract_temp_file_path(upload)
      raise "Temporary file not found: #{temp_file_path}" unless temp_file_path.present? && File.exist?(temp_file_path)

      dirs = setup_directories(upload)
      formats = []
      update_upload_progress(upload, 20)

      mp4_path = copy_original_video(temp_file_path, dirs[:videos_dir])
      formats << 'mp4'
      update_upload_progress(upload, 40)

      thumbnail_path = create_thumbnail(mp4_path, dirs[:thumbnail_dir])
      update_upload_progress(upload, 50)

      hls_result = convert_to_hls(mp4_path, dirs[:hls_dir])
      formats << 'hls' if hls_result[:success]
      update_upload_progress(upload, 80)

      video_info = extract_video_info(mp4_path)
      cdn_url = determine_cdn_url(upload.id, formats)

      update_upload_progress(upload, 100, 'success', {
        cdn_url: cdn_url,
        thumbnail_path: "/uploads/thumbnails/#{upload.id}/thumbnail.jpg",
        formats: formats,
        duration: video_info[:duration].to_i,
        quality_360p_url: hls_result[:quality_urls]['360p'],
        quality_480p_url: hls_result[:quality_urls]['480p'],
        quality_720p_url: hls_result[:quality_urls]['720p']
      })

      Rails.logger.info "Xử lý video hoàn tất: #{cdn_url}"
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

  def setup_directories(upload)
    dirs = {
      videos_dir: Rails.root.join('public', 'uploads', 'videos', upload.id.to_s),
      hls_dir: Rails.root.join('public', 'uploads', 'hls', upload.id.to_s),
      thumbnail_dir: Rails.root.join('public', 'uploads', 'thumbnails', upload.id.to_s)
    }

    dirs.values.each do |dir|
      FileUtils.mkdir_p(dir)
      FileUtils.chmod(0o755, dir)
    end

    dirs
  end

  def copy_original_video(temp_file_path, videos_dir)
    # Luôn chuyển đổi thành MP4 bất kể định dạng đầu vào là gì
    mp4_path = File.join(videos_dir, 'video.mp4')

    # Sử dụng ffmpeg để chuyển đổi file từ bất kỳ định dạng video nào sang MP4
    convert_cmd = "ffmpeg -y -i #{temp_file_path} -c:v libx264 -preset medium -crf 23 -c:a aac -b:a 128k #{mp4_path}"
    system(convert_cmd)

    # Kiểm tra xem file MP4 đã được tạo thành công chưa
    unless File.exist?(mp4_path) && File.size?(mp4_path).to_i > 0
      # Nếu không thành công, thử phương pháp copy thẳng
      Rails.logger.warn "Không thể chuyển đổi video sang MP4, thử phương pháp copy trực tiếp"
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
      position_formatted = Time.at(thumbnail_position).utc.strftime("%H:%M:%S")

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
    if duration_seconds > 0
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
      quality_urls: {
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

        if quality_result[:success]
          master_content += quality_result[:master_content]
          result[:quality_urls][quality] = quality_result[:url]
          hls_success = true
        end
      end

      if hls_success
        File.write(master_m3u8_path, master_content)
        FileUtils.chmod(0o644, master_m3u8_path)
        result[:success] = true
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
    result = { success: false, master_content: '', url: nil }

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

      result[:master_content] = "#EXT-X-STREAM-INF:BANDWIDTH=#{bandwidth},RESOLUTION=#{width != -2 ? width : 'auto'}x#{height}\n"
      result[:master_content] += "#{quality}/playlist.m3u8\n"

      FileUtils.chmod(0o644, playlist_m3u8_path)
      FileUtils.chmod(0o644, Dir.glob("#{quality_dir}/*.ts"))

      result[:url] = "/uploads/hls/#{File.basename(File.dirname(hls_dir))}/#{quality}/playlist.m3u8"
      result[:success] = true

      Rails.logger.info "Chuyển đổi HLS #{quality} thành công với đường dẫn: #{result[:url]}"
    else
      Rails.logger.warn "Không thể tạo HLS playlist cho #{quality}"
    end

    result
  end

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
    begin
      duration_seconds = get_video_duration(mp4_path)

      resolution_cmd = "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 #{mp4_path}"
      resolution = `#{resolution_cmd}`.strip

      Rails.logger.info "Thông tin video: Thời lượng = #{duration_seconds}s, Độ phân giải = #{resolution}"

      { duration: duration_seconds, resolution: resolution }
    rescue StandardError => e
      Rails.logger.error "Lỗi khi lấy thông tin video: #{e.message}"
      { duration: 0, resolution: '0x0' }
    end
  end

  def determine_cdn_url(upload_id, formats)
    if formats.include?('hls')
      "/uploads/hls/#{upload_id}/master.m3u8"
    else
      "/uploads/videos/#{upload_id}/video.mp4"
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
    attrs.merge!(additional_attrs) if additional_attrs.present?

    Rails.logger.info "Cập nhật tiến trình xử lý video #{upload.id}: #{progress}% - #{status || 'đang tiếp tục'}"
    result = upload.update(attrs)

    unless result
      Rails.logger.error "Không thể cập nhật tiến trình cho upload #{upload.id}: #{upload.errors.full_messages.join(', ')}"
    end

    result
  end
end
