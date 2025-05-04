# frozen_string_literal: true

class Manage::ModerationsController < Manage::BaseController
  before_action :set_video

  def update
    case params[:action_type]
    when 'approve'
      @video.update(moderation_status: :approved)
      redirect_to manage_video_path(@video), notice: 'Video has been approved.'
    when 'reject'
      @video.update(moderation_status: :rejected)
      redirect_to manage_video_path(@video), notice: 'Video has been rejected.'
    when 'lock'
      @video.update(moderation_status: :locked)
      redirect_to manage_video_path(@video), notice: 'Video has been locked.'
    else
      redirect_to manage_video_path(@video), alert: 'Invalid action.'
    end
  end

  private

  def set_video
    @video = Video.find(params[:video_id])
  end
end
