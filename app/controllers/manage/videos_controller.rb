# frozen_string_literal: true

class Manage::VideosController < Manage::BaseController
  before_action :set_video, only: %i[show edit update destroy]

  def index
    @videos = filter_videos
  end

  def show; end

  def new
    @video = Video.new
  end

  def edit; end

  def create
    @video = Video.new(video_params)

    if @video.save
      redirect_to manage_video_path(@video), notice: 'Video has been successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @video.update(video_params)
      redirect_to manage_video_path(@video), notice: 'Video has been successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @video.destroy
    redirect_to manage_videos_path, notice: 'Video has been successfully deleted.'
  end

  private

  def filter_videos
    videos = Video.joins(:upload)
                .includes(:lesson, upload: :user)
                .where(uploads: { status: :success })
                .order(created_at: :desc)

    if params[:status].present? && params[:status].to_sym != :success
      videos = Video.includes(:lesson, upload: :user)
                  .joins(:upload)
                  .where(uploads: { status: params[:status] })
                    .order(created_at: :desc)
    end

    videos = videos.where(uploads: { user_id: params[:instructor_id] }) if params[:instructor_id].present?
    videos = videos.where(uploads: { moderation_status: params[:moderation_status].to_sym }) if params[:moderation_status].present?
    videos = videos.joins(lesson: { chapter: :course }).where(chapters: { course_id: params[:course_id] }) if params[:course_id].present?

    if params[:filename].present?
      search_term = "%#{params[:filename]}%"
      videos = videos.where("uploads.filename ILIKE ? OR videos.title ILIKE ?", search_term, search_term)
    end

    videos = videos.where("videos.created_at >= ?", params[:created_from].to_date.beginning_of_day) if params[:created_from].present?
    videos = videos.where("videos.created_at <= ?", params[:created_to].to_date.end_of_day) if params[:created_to].present?

    videos.page(params[:page]).per(params[:per_page] || 10)
  end

  def set_video
    @video = Video.includes(:lesson, upload: :user).find_by(id: params[:id])
    redirect_to manage_videos_path, alert: 'Video not found.' unless @video
  end

  def video_params
    params.require(:video).permit(:title, :lesson_id, :is_locked, :position, :thumbnail, :upload_id)
  end
end
