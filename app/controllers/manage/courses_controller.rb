# frozen_string_literal: true

module Manage
  class CoursesController < Manage::BaseController
    before_action :set_course, only: %i[show edit update destroy publish draft]
    before_action :set_categories, only: %i[new edit create update]
    before_action :load_categories_for_filter, only: %i[index]

    def index
      @courses = find_courses
    end

    def show
    end

    def new
      @course = Course.new
    end

    def edit
    end

    def create
      @course = current_user.courses.build(course_params)

      if @course.save
        handle_categories
        redirect_to manage_course_path(@course), notice: 'Course has been successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @course.update(course_params)
        handle_categories
        redirect_to manage_course_path(@course), notice: 'Course has been successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @course.destroy
      redirect_to manage_courses_path, notice: 'Course has been successfully deleted.'
    end

    def publish
      @course.update(status: 'published')
      redirect_to manage_course_path(@course), notice: 'Course has been published.'
    end

    def draft
      @course.update(status: 'draft')
      redirect_to manage_course_path(@course), notice: 'Course has been changed to draft.'
    end

    private

    def find_courses
      courses = Course.includes(:categories)

      courses = courses.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?
      courses = courses.where(status: params[:status]) if params[:status].present?

      if params[:category_id].present?
        courses = courses.joins(:course_categories)
                         .where(course_categories: { category_id: params[:category_id] })
      end

      courses = courses.where(language: params[:language]) if params[:language].present?
      courses = courses.where('price >= ?', params[:min_price].to_f) if params[:min_price].present?
      courses = courses.where('price <= ?', params[:max_price].to_f) if params[:max_price].present?
      courses = courses.where(user_id: params[:instructor_id]) if params[:instructor_id].present?

      courses.order(created_at: :desc)
             .page(params[:page])
             .per(params[:per_page] || 10)
    end

    def set_course
      @course = Course.find(params[:id])
    end

    def set_categories
      @categories = Category.all.order(:name)
    end

    def load_categories_for_filter
      @categories_for_filter = Category.all.order(:name)
    end

    def course_params
      params.require(:course).permit(
        :title, :description, :price, :thumbnail_path,
        :language, :status, :thumbnail
      )
    end

    def handle_categories
      if params[:course][:category_ids].present?
        selected_categories = params[:course][:category_ids].reject(&:blank?).map(&:to_i)

        @course.course_categories.where.not(category_id: selected_categories).destroy_all

        selected_categories.each do |category_id|
          @course.course_categories.find_or_create_by(category_id: category_id)
        end
      else
        @course.course_categories.destroy_all
      end
    end
  end
end
