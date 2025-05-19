# frozen_string_literal: true

class Dashboard::ViewersController < Dashboard::DashboardController
  before_action :authenticate_user!

  def index; end

  def show
    @course = Course.find(params[:id])

    if request.query_parameters.empty?
      first_lesson = @course.lessons.order(:position).first
      first_video = first_lesson&.videos&.order(:position)&.first if first_lesson

      if first_lesson && first_video
        redirect_to dashboard_course_viewer_path(@course, lesson_id: first_lesson.id, video_id: first_video.id)
        return
      end
    end

    @current_lesson = @course.lessons.find_by(id: params[:lesson_id]) if params[:lesson_id]
    @current_video = @current_lesson&.videos&.find_by(id: params[:video_id]) if params[:video_id]

    if @current_video && !@current_video.is_locked.nil?
      redirect_to dashboard_courses_path, alert: 'Bạn không có quyền xem video này'
      return
    end

    @next_lesson = find_next_lesson if @current_lesson
  end

  private

  def find_next_lesson
    current_chapter = @current_lesson.chapter
    current_lesson_index = current_chapter.lessons.index(@current_lesson)

    next_lesson = current_chapter.lessons[current_lesson_index + 1] if current_lesson_index

    unless next_lesson
      current_chapter_index = @course.chapters.index(current_chapter)
      if current_chapter_index
        next_chapter = @course.chapters[current_chapter_index + 1]
        next_lesson = next_chapter&.lessons&.first
      end
    end

    next_lesson
  end
end
