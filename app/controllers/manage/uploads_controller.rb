# frozen_string_literal: true

class Manage::UploadsController < Manage::BaseController
  before_action :set_upload, only: %i[show update destroy progress retry]

  def index
    @uploads = Upload.includes(:user).order(created_at: :desc).page(params[:page]).per(10)
  end

  def show; end

  def new
    @upload = Upload.new
  end

  def create
    @upload = Upload.new(user: current_user)
    @upload.status = 'pending'
    @upload.progress = 0

    begin
      if params[:upload] && params[:upload][:video].present?
        video_file = params[:upload][:video]

        # Kiểm tra định dạng file video
        unless video_file.content_type.start_with?('video/')
          respond_to do |format|
            format.html do
              flash.now[:alert] = 'Please upload a valid video file. Supported formats: MP4, MOV, AVI, MKV, WebM, etc.'
              render :new, status: :unprocessable_entity
            end
            format.json { render json: { success: false, errors: ['Invalid file format. Please upload a video file.'] }, status: :bad_request }
          end
          return
        end

        @upload.file_type = video_file.content_type.split('/').last
        @upload.cdn_url = 'placeholder_url'
        @upload.thumbnail_path = 'placeholder_thumbnail'
        @upload.duration = 0
        @upload.formats = []

        temp_dir = Rails.root.join('tmp', 'videos')
        FileUtils.mkdir_p(temp_dir)

        original_filename = video_file.original_filename
        temp_file_path = Rails.root.join('tmp', 'videos', "#{SecureRandom.uuid}_#{original_filename}")

        File.open(temp_file_path, 'wb') do |file|
          file.write(video_file.read)
        end

        upload_dirs = [
          Rails.root.join('public', 'uploads'),
          Rails.root.join('public', 'uploads', 'videos'),
          Rails.root.join('public', 'uploads', 'thumbnails'),
          Rails.root.join('tmp', 'videos')
        ]

        upload_dirs.each do |dir|
          FileUtils.mkdir_p(dir)
          FileUtils.chmod(0o755, dir)
        end

        test_file_path = Rails.root.join('public', 'uploads', 'test_write_permission.txt')
        begin
          File.open(test_file_path, 'w') { |f| f.write('test') }
          File.delete(test_file_path) if File.exist?(test_file_path)
        rescue StandardError => e
          Rails.logger.error "✗ Không có quyền ghi vào thư mục public/uploads: #{e.message}"
        end

        if @upload.save
          @upload.update(processing_log: temp_file_path.to_s)

          VideoProcessingJob.perform_later(@upload.id)

          @upload.update(status: 'processing', progress: 10)

          respond_to do |format|
            format.html do
              redirect_to manage_upload_path(@upload),
                          notice: 'Upload started successfully. Video is being processed in background.'
            end
            format.json { render json: { success: true, upload_id: @upload.id }, status: :created }
          end
        else
          File.delete(temp_file_path) if File.exist?(temp_file_path)

          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.json do
              render json: { success: false, errors: @upload.errors.full_messages }, status: :unprocessable_entity
            end
          end
        end
      else
        Rails.logger.error 'Không tìm thấy file video trong params'
        respond_to do |format|
          format.html do
            flash.now[:alert] = 'Please select a video file to upload'
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { success: false, errors: ['No video file found'] }, status: :bad_request }
        end
      end
    rescue StandardError => e
      Rails.logger.error "Lỗi khi tạo upload: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      respond_to do |format|
        format.html do
          flash.now[:alert] = 'An error occurred while processing your video. Please try again later.'
          render :new, status: :internal_server_error
        end
        format.json { render json: { success: false, errors: [e.message] }, status: :internal_server_error }
      end
    end
  end

  def update
    if @upload.update(upload_params)
      redirect_to manage_upload_path(@upload), notice: 'Upload was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @upload.destroy
    redirect_to manage_uploads_path, notice: 'Upload was successfully deleted.'
  end

  def progress
    if @upload
      render json: {
        id: @upload.id,
        status: @upload.status,
        progress: @upload.progress || 0
      }
    else
      render json: {
        error: 'Upload not found'
      }, status: :not_found
    end
  end

  def retry
    if @upload.status != 'failed'
      redirect_to manage_upload_path(@upload), alert: 'Chỉ có thể thử lại các upload đã thất bại.'
      return
    end

    temp_file_path = begin
      @upload.processing_log.to_s.split("\n").first
    rescue StandardError
      nil
    end

    if temp_file_path.blank? || !temp_file_path.include?('/') || !File.exist?(temp_file_path)
      redirect_to manage_upload_path(@upload), alert: 'Không thể thử lại vì file nguồn đã bị xóa.'
      return
    end

    @upload.update(
      status: 'processing',
      progress: 10,
      processing_log: temp_file_path
    )

    VideoProcessingJob.perform_later(@upload.id)

    redirect_to manage_upload_path(@upload), notice: 'Đã khởi động lại quá trình xử lý video.'
  end

  private

  def set_upload
    @upload = Upload.includes(:user).find(params[:id])
  end

  def upload_params
    params.require(:upload).permit(:video, :cdn_url, :file_type, :thumbnail_path, :duration, :formats,
                                   :status, :progress, :processing_log, :quality_360p_url, :quality_480p_url, :quality_720p_url)
  end
end
