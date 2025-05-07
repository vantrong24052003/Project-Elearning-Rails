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

    upload.update(status: 'processing', progress: 10)

    begin
      temp_file_path = begin
        upload.processing_log.to_s.split("\n").first
      rescue StandardError
        nil
      end

      raise "Temporary file not found: #{temp_file_path}" unless temp_file_path.present? && File.exist?(temp_file_path)

      videos_dir = Rails.root.join('public', 'uploads', 'videos', upload.id.to_s)
      hls_dir = Rails.root.join('public', 'uploads', 'hls', upload.id.to_s)
      thumbnail_dir = Rails.root.join('public', 'uploads', 'thumbnails', upload.id.to_s)

      [videos_dir, hls_dir, thumbnail_dir].each do |dir|
        FileUtils.mkdir_p(dir)
        FileUtils.chmod(0o755, dir)
      end

      formats = []

      upload.update(progress: 20)

      mp4_path = File.join(videos_dir, 'video.mp4')
      FileUtils.cp(temp_file_path, mp4_path)
      FileUtils.chmod(0o644, mp4_path)

      formats << 'mp4'

      upload.update(progress: 40)

      thumbnail_path = File.join(thumbnail_dir, 'thumbnail.jpg')

      thumbnail_cmd = "ffmpeg -y -i #{mp4_path} -ss 00:00:03 -vframes 1 -f image2 #{thumbnail_path}"
      system(thumbnail_cmd)

      unless File.exist?(thumbnail_path) && File.size(thumbnail_path).positive?
        File.open(thumbnail_path, 'w') { |f| f.write('') }
      end

      FileUtils.chmod(0o644, thumbnail_path)
      Rails.logger.info "Đã tạo thumbnail tại: #{thumbnail_path}"

      upload.update(progress: 50)

      hls_success = false
      begin
        master_m3u8_path = File.join(hls_dir, 'master.m3u8')

        qualities = {
          '360p' => { height: 360, bitrate: '800k' },
          '480p' => { height: 480, bitrate: '1400k' },
          '720p' => { height: 720, bitrate: '2800k' }
        }

        FileUtils.rm_f(Dir.glob("#{hls_dir}/*.m3u8"))
        FileUtils.rm_f(Dir.glob("#{hls_dir}/*.ts"))
        qualities.each_key do |quality|
          quality_dir = File.join(hls_dir, quality)
          FileUtils.mkdir_p(quality_dir)
          FileUtils.rm_f(Dir.glob("#{quality_dir}/*"))
        end

        Rails.logger.info "Bắt đầu chuyển đổi HLS cho file: #{mp4_path}"

        master_content = "#EXTM3U\n#EXT-X-VERSION:3\n"

        qualities.each do |quality, options|
          quality_dir = File.join(hls_dir, quality)
          playlist_m3u8_path = File.join(quality_dir, 'playlist.m3u8')
          segments_path = File.join(quality_dir, 'segment_%03d.ts')

          width = -2
          height = options[:height]
          bitrate = options[:bitrate]

          ffmpeg_cmd = "ffmpeg -y -i #{mp4_path} " \
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
                       "-hls_segment_filename \"#{segments_path}\" \"#{playlist_m3u8_path}\""

          Rails.logger.info "Tạo HLS #{quality} với lệnh: #{ffmpeg_cmd}"

          system(ffmpeg_cmd)

          if File.exist?(playlist_m3u8_path)
            bandwidth = case quality
                        when '360p' then 800_000
                        when '480p' then 1_400_000
                        when '720p' then 2_800_000
                        else 1_400_000
                        end

            master_content += "#EXT-X-STREAM-INF:BANDWIDTH=#{bandwidth},RESOLUTION=#{width != -2 ? width : 'auto'}x#{height}\n"
            master_content += "#{quality}/playlist.m3u8\n"

            FileUtils.chmod(0o644, playlist_m3u8_path)
            FileUtils.chmod(0o644, Dir.glob("#{quality_dir}/*.ts"))

            hls_success = true
            Rails.logger.info "Chuyển đổi HLS #{quality} thành công"
          else
            Rails.logger.warn "Không thể tạo HLS playlist cho #{quality}"
          end
        end

        if hls_success
          File.write(master_m3u8_path, master_content)
          FileUtils.chmod(0o644, master_m3u8_path)
          formats << 'hls'
          Rails.logger.info 'Tạo master playlist HLS thành công'
        else
          Rails.logger.warn 'Không thể tạo master playlist HLS'
        end
      rescue StandardError => e
        Rails.logger.error "Lỗi khi chuyển đổi HLS: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end

      upload.update(progress: 80)

      begin
        duration_cmd = "ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 #{mp4_path}"
        duration_seconds = `#{duration_cmd}`.strip.to_f

        resolution_cmd = "ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 #{mp4_path}"
        resolution = `#{resolution_cmd}`.strip

        Rails.logger.info "Thông tin video: Thời lượng = #{duration_seconds}s, Độ phân giải = #{resolution}"
      rescue StandardError => e
        Rails.logger.error "Lỗi khi lấy thông tin video: #{e.message}"
        duration_seconds = 0
        resolution = '0x0'
      end

      cdn_url = if formats.include?('hls')
                  "/uploads/hls/#{upload.id}/master.m3u8"
                else
                  "/uploads/videos/#{upload.id}/video.mp4"
                end

      upload.update(
        cdn_url: cdn_url,
        thumbnail_path: "/uploads/thumbnails/#{upload.id}/thumbnail.jpg",
        formats: formats,
        status: 'success',
        progress: 100,
        duration: duration_seconds.to_i,
        resolution: resolution
      )

      Rails.logger.info "Xử lý video hoàn tất: #{cdn_url}"
    rescue StandardError => e
      error_log = "Error processing video: #{e.message}\n#{e.backtrace.join("\n")}"

      error_log = "#{temp_file_path}\n#{error_log}" if temp_file_path.present?

      upload.update(
        status: 'failed',
        progress: 0,
        processing_log: error_log
      )

      # Báo cáo lỗi chi tiết hơn
      Rails.logger.error "Video processing failed for upload ##{upload_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Re-raise lỗi để Sidekiq có thể retry
      raise e
    end
  end
end
