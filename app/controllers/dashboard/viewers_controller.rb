# frozen_string_literal: true

class Dashboard::ViewersController < Dashboard::DashboardController
  before_action :authenticate_user!
  before_action :set_course, only: %i[show]
  before_action :initialize_viewer_service

  def show
    if !@viewer_service.authorize_course_access(@course)
      redirect_to dashboard_course_path(@course), alert: 'You are not authorized to view this course'
      return
    end

    if request.query_parameters.empty?
      first_lesson, first_video = @viewer_service.get_first_lesson_and_video(@course)

      if first_lesson && first_video
        redirect_to dashboard_course_viewer_path(@course, lesson_id: first_lesson.id, video_id: first_video.id)
        return
      end
    end

    @current_lesson, @current_video = @viewer_service.get_current_lesson_and_video(
      @course, params[:lesson_id], params[:video_id]
    )
    @course_structure = @viewer_service.get_course_structure(@course)
    @user_progress = @viewer_service.get_user_progress(@course)
  end

  private

  def set_course
    @course = Course.find_by(id: params[:id])
    return unless @course.nil?

    redirect_to dashboard_courses_path, alert: 'Course not found'
  end

  def initialize_viewer_service
    @viewer_service = Dashboard::ViewerService.new(current_user)
  end
end
