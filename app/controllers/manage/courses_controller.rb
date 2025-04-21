# frozen_string_literal: true

module Manage
  class CoursesController < Manage::BaseController
    before_action :set_course, only: %i[show edit update destroy]

    def index
      @courses = Course.all
      @courses = @courses.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?
      if params[:category_id].present?
        @courses = @courses.joins(:course_categories).where(course_categories: { category_id: params[:category_id] })
      end
      @courses = @courses.where(status: params[:status]) if params[:status].present?
    end

    def show; end

    def new
      @course = Course.new
    end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to manage_course_path(@course), notice: 'Course was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @course.update(course_params)
        redirect_to manage_course_path(@course), notice: 'Course was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @course.destroy
      redirect_to manage_courses_path, notice: 'Course was successfully deleted.'
    end

    def bulk_publish
      @courses = Course.where(id: params[:course_ids])
      count = @courses.update_all(status: 'published')

      respond_to do |format|
        format.html do
          flash[:notice] = "#{count} khóa học đã được xuất bản thành công."
          redirect_to manage_courses_path
        end
        format.turbo_stream
      end
    end

    def bulk_draft
      @courses = Course.where(id: params[:course_ids])
      count = @courses.update_all(status: 'draft')

      respond_to do |format|
        format.html do
          flash[:notice] = "#{count} khóa học đã được cập nhật thành bản nháp."
          redirect_to manage_courses_path
        end
        format.turbo_stream
      end
    end

    def bulk_delete
      @courses = Course.where(id: params[:course_ids])
      count = @courses.destroy_all.count

      respond_to do |format|
        format.html do
          flash[:notice] = "#{count} khóa học đã được xóa thành công."
          redirect_to manage_courses_path
        end
        format.turbo_stream
      end
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(:title, :description, :price, :thumbnail_path, :language, :status, :user_id)
    end
  end
end
