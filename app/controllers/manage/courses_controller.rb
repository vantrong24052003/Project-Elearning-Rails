# frozen_string_literal: true

class Manage::CoursesController < Manage::BaseController
  before_action :set_course, only: %i[show edit update destroy]
  before_action :set_categories, only: %i[new edit create update]
  before_action :initialize_course_service, only: %i[index create update]

  def index
    @categories_for_filter = Category.all.order(:name)
    @courses = @course_service.find_courses(params)
  end

  def show; end

  def new
    @course = Course.new
  end

  def edit
    @categories = Category.all.order(:name)
  end

  def create
    @course = current_user.courses.build(course_params)

    if @course.save
      @course_service.handle_categories(@course, params[:course][:category_ids])
      redirect_to manage_course_path(@course), notice: 'Course has been successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    case params[:action_type]&.to_sym
    when :publish
      if @course_service.publish_course(@course)
        redirect_to manage_course_path(@course), notice: 'Course has been published.'
      else
        redirect_to manage_course_path(@course), alert: 'Failed to publish course.'
      end
    when :draft
      if @course_service.draft_course(@course)
        redirect_to manage_course_path(@course), notice: 'Course has been changed to draft.'
      else
        redirect_to manage_course_path(@course), alert: 'Failed to change course to draft.'
      end
    else
      if @course.update(course_params)
        @course_service.handle_categories(@course, params[:course][:category_ids])
        redirect_to manage_course_path(@course), notice: 'Course has been successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end
  end

  def destroy
    @course.destroy
    redirect_to manage_courses_path, notice: 'Course has been successfully deleted.'
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def set_categories
    @categories = Category.all.order(:name)
  end

  def initialize_course_service
    @course_service = Manage::CourseService.new(current_user)
  end

  def course_params
    params.require(:course).permit(
      :title, :description, :price, :thumbnail_path,
      :language, :status, :thumbnail, category_ids: []
    )
  end
end
