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
    videos = Video.includes(:lesson, upload: :user)
                  .order(created_at: :desc)

    videos = videos.joins(:upload).where(uploads: { status: params[:status] }) if params[:status].present?

    videos = videos.where(moderation_status: params[:moderation_status]) if params[:moderation_status].present?

    if params[:course_id].present?
      videos = videos.joins(lesson: { chapter: :course }).where(chapters: { course_id: params[:course_id] })
    end

    if params[:created_from].present?
      videos = videos.where('videos.created_at >= ?',
                            params[:created_from].to_date.beginning_of_day)
    end
    if params[:created_to].present?
      videos = videos.where('videos.created_at <= ?',
                            params[:created_to].to_date.end_of_day)
    end

    videos.page(params[:page]).per(params[:per_page] || 10)
  end

  def set_video
    @video = Video.includes(:lesson, upload: :user).find_by(id: params[:id])
  end

  def video_params
    params.require(:video).permit(:title, :lesson_id, :is_locked, :position, :thumbnail, :upload_id, :moderation_status)
  end
end
