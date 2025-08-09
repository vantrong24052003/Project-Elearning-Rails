# frozen_string_literal: true

class Dashboard::CoursesController < Dashboard::DashboardController
  before_action :set_course, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[index new edit update]
  before_action :initialize_course_service, only: %i[index show]

  def index
    @courses = @course_service.filter_and_paginate_courses(params).page(params[:page]).per(24)
    @selected_category_name = @categories.find_by(id: params[:category_id])&.name if params[:category_id].present?
  end

  def show
    if @course.status.to_sym != :published
      redirect_to dashboard_courses_path, alert: 'Course not available.'
      return
    end
    @chapters = @course.chapters
    @lessons = Lesson.where(chapter_id: @chapters.pluck(:id))
    @videos = Video.includes(:upload).where(lesson_id: @lessons.pluck(:id))
    @total_duration = @course_service.calculate_course_statistics(@videos)
    @related_courses = @course_service.get_related_courses(@course)
  end

  def new
    @course = Course.new
  end

  def create
    @course = current_user.courses.build(permit_params)

    if @course.save
      redirect_to dashboard_course_path(@course), notice: 'Course was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @course.update(permit_params)
      redirect_to dashboard_course_path(@course), notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @course.destroy
    redirect_to dashboard_courses_path, notice: 'Course was successfully deleted.'
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def set_categories
    @categories = Category.all
  end

  def initialize_course_service
    @course_service = Dashboard::CourseService.new(current_user)
  end

  def permit_params
    params.require(:course).permit(:title, :description, :price, :thumbnail_path, :language, :status, category_ids: [])
  end
end
