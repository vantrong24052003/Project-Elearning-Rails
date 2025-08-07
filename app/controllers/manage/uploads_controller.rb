# frozen_string_literal: true

class Manage::UploadsController < Manage::BaseController
  before_action :set_upload, only: %i[show update destroy progress retry]

  def index
    @uploads = if current_user.has_role?(:admin)
                 Upload.includes(:user).order(created_at: :desc)
               else
                 Upload.includes(:user).where(user_id: current_user.id).order(created_at: :desc)
               end.page(params[:page]).per(10)
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
        unless video_file.content_type.start_with?('video/')
          respond_to do |format|
            format.html do
              flash.now[:alert] = 'Please upload a valid video file. Supported formats: MP4, MOV, AVI, MKV, WebM, etc.'
              render :new, status: :unprocessable_entity
            end
            format.json do
              render json: { success: false, errors: ['Invalid file format. Please upload a video file.'] },
                     status: :bad_request
            end
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
        respond_to do |format|
          format.html do
            flash.now[:alert] = 'Please select a video file to upload'
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { success: false, errors: ['No video file found'] }, status: :bad_request }
        end
      end
    rescue StandardError => e
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
      response = {
        id: @upload.id,
        status: @upload.status,
        progress: @upload.progress || 0
      }

      if @upload.status == 'success'
        response.merge!({
                          cdn_url: @upload.cdn_url,
                          thumbnail_url: @upload.thumbnail_path,
                          duration: @upload.duration,
                          formats: @upload.formats
                        })
      end

      render json: response
    else
      render json: {
        error: 'Upload not found'
      }, status: :not_found
    end
  end

  def retry
    if @upload.status != 'failed'
      redirect_to manage_upload_path(@upload), alert: 'Only failed uploads can be retried.'
      return
    end

    temp_file_path = begin
      @upload.processing_log.to_s.split("\n").first
    rescue StandardError
      nil
    end

    if temp_file_path.blank? || !temp_file_path.include?('/') || !File.exist?(temp_file_path)
      redirect_to manage_upload_path(@upload), alert: 'Cannot retry because the source file has been deleted.'
      return
    end

    @upload.update(
      status: 'processing',
      progress: 10,
      processing_log: temp_file_path
    )

    VideoProcessingJob.perform_later(@upload.id)

    redirect_to manage_upload_path(@upload), notice: 'Video processing has been restarted.'
  end

  private

  def set_upload
    @upload = if current_user.has_role?(:admin)
                Upload.includes(:user).find(params[:id])
              else
                Upload.includes(:user).where(user_id: current_user.id).find(params[:id])
              end
  end

  def upload_params
    params.require(:upload).permit(:video, :cdn_url, :file_type, :thumbnail_path, :duration, :formats,
                                   :status, :progress, :processing_log, :quality_360p_url, :quality_480p_url, :quality_720p_url)
  end
end
