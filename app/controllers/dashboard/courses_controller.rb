# frozen_string_literal: true

# File moved to `app/controllers/dashboard_courses_controller.rb`

module Dashboard
  class CoursesController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    before_action :set_course, only: %i[show edit update destroy]

    def index
      @courses = Course.all

      # Apply filters
      if params[:search].present?
        @courses = @courses.where('title LIKE ? OR description LIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
      end

      if params[:category].present?
        category = Category.find_by(name: params[:category])
        @courses = @courses.joins(:course_categories).where(course_categories: { category_id: category.id }) if category
      end

      @courses = @courses.where('price >= ?', params[:price_min]) if params[:price_min].present?
      @courses = @courses.where('price <= ?', params[:price_max]) if params[:price_max].present?

      # Pagination
      @courses = @courses.page(params[:page]).per(12)
    end

    def show
      @chapters = @course.chapters.order(:position)
    end

    def new
      @course = Course.new
    end

    def create
      @course = Course.new(course_params)
      if @course.save
        redirect_to dashboard_course_path(@course), notice: 'Course was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @course.update(course_params)
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

    def course_params
      params.require(:course).permit(:title, :description, :price, :thumbnail_path, :language, :status, :user_id)
    end

    def render_not_found
      render file: Rails.root.join('public', '404.html'), status: :not_found, layout: false
    end
  end
end
