# frozen_string_literal: true

class Dashboard::CoursesController < ApplicationController
  include AccountSecurity
  before_action :check_locked_account
  before_action :initialize_course_service, only: %i[index show]

  def index
    @categories = Category.all
    @courses = @course_service.filter_courses(params).page(params[:page]).per(24)
    @selected_category_name = @categories.find_by(id: params[:category_id])&.name if params[:category_id].present?
  end

  def show
    @course = Course.find(params[:id])
    return redirect_to dashboard_courses_path, alert: 'Course not available.' unless @course.published?

    @chapters = @course.chapters
    @lessons = Lesson.where(chapter_id: @chapters.pluck(:id))
    @videos = Video.includes(:upload).where(lesson_id: @lessons.pluck(:id))
    @total_duration = @course_service.calculate_course_statistics(@videos)
    @total_duration = @course_service.calculate_course_statistics(@videos)
    @related_courses = @course_service.get_related_courses(@course)
  end

  private

  def initialize_course_service
    @course_service = Dashboard::CourseService.new
  end

  def permit_params
    params.require(:course).permit(:title, :description, :price, :thumbnail_path, :language, :status, category_ids: [])
  end
end
