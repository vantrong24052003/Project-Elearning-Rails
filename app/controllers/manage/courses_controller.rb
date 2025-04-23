# frozen_string_literal: true

module Manage
  class CoursesController < Manage::BaseController
    before_action :set_course, only: %i[show edit update destroy publish draft]
    before_action :set_categories, only: %i[new edit create update]

    def index
      @courses = Course.includes(:categories)
                       .search_by_params(params)
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(params[:per_page] || 10)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      render :show
    end

    def new
      @course = Course.new

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'modal',
            partial: 'manage/courses/form',
            locals: { course: @course, categories: @categories }
          )
        end
      end
    end

    def edit
      @course = Course.find(params[:id])

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'modal',
            partial: 'manage/courses/form',
            locals: { course: @course, categories: @categories }
          )
        end
      end
    end

    def create
      @course = current_user.courses.build(course_params)

      respond_to do |format|
        if @course.save
          handle_categories
          format.html { redirect_to manage_course_path(@course), notice: 'Khóa học đã được tạo thành công.' }
          format.turbo_stream do
            flash.now[:success] = 'Khóa học đã được tạo thành công.'
            render turbo_stream: [
              turbo_stream.update('courses_list', partial: 'manage/courses/courses_list',
                                                  locals: { courses: Course.includes(:user, :categories).order(created_at: :desc).page(1).per(10) }),
              turbo_stream.replace('modal', ''),
              turbo_stream.prepend('flash-container', partial: 'shared/flash',
                                                      locals: { type: :success, message: 'Khóa học đã được tạo thành công.' })
            ]
          end
        else
          format.html { render :new }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'modal',
              partial: 'manage/courses/form',
              locals: { course: @course, categories: @categories }
            )
          end
        end
      end
    end

    def update
      respond_to do |format|
        if @course.update(course_params)
          handle_categories
          format.html { redirect_to manage_course_path(@course), notice: 'Khóa học đã được cập nhật thành công.' }
          format.turbo_stream do
            flash.now[:success] = 'Khóa học đã được cập nhật thành công.'
            render turbo_stream: [
              turbo_stream.replace("course_#{@course.id}", partial: 'manage/courses/course',
                                                           locals: { course: @course }),
              turbo_stream.replace('modal', ''),
              turbo_stream.prepend('flash-container', partial: 'shared/flash',
                                                      locals: { type: :success, message: 'Khóa học đã được cập nhật thành công.' })
            ]
          end
        else
          format.html { render :edit }
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              'modal',
              partial: 'manage/courses/form',
              locals: { course: @course, categories: @categories }
            )
          end
        end
      end
    end

    def destroy
      @course.destroy

      respond_to do |format|
        format.html { redirect_to manage_courses_path, notice: 'Khóa học đã được xóa thành công.' }
        format.turbo_stream do
          flash.now[:success] = 'Khóa học đã được xóa thành công.'
          render turbo_stream: [
            turbo_stream.remove("course_#{@course.id}"),
            turbo_stream.prepend('flash-container', partial: 'shared/flash',
                                                    locals: { type: :success, message: 'Khóa học đã được xóa thành công.' })
          ]
        end
      end
    end

    def publish
      @course = Course.find(params[:id])
      @course.update(status: 'published')

      respond_to do |format|
        format.html { redirect_to manage_course_path(@course), notice: 'Khóa học đã được xuất bản.' }
        format.turbo_stream do
          flash.now[:notice] = 'Khóa học đã được xuất bản.'
          render :status_update 
        end
      end
    end

    def draft
      @course = Course.find(params[:id])
      @course.update(status: 'draft')

      respond_to do |format|
        format.html { redirect_to manage_course_path(@course), notice: 'Khóa học đã được chuyển thành bản nháp.' }
        format.turbo_stream do
          flash.now[:notice] = 'Khóa học đã được chuyển thành bản nháp.'
          render :status_update
        end
      end
    end

    def bulk_publish
      @courses = Course.where(id: params[:course_ids])
      count = @courses.update_all(status: 'published')

      respond_to do |format|
        format.html do
          redirect_to manage_courses_path, notice: 'khóa học đã được xuất bản thành công.'
        end
        format.turbo_stream do
          render partial: 'manage/courses/course_stream', formats: [:turbo_stream],
                 locals: { courses: @courses, message: "#{count} khóa học đã được xuất bản thành công.", flash_type: 'success' }
        end
      end
    end

    def bulk_draft
      @courses = Course.where(id: params[:course_ids])
      count = @courses.update_all(status: 'draft')

      respond_to do |format|
        format.html do
          redirect_to manage_courses_path, notice: 'khóa học đã được cập nhật thành bản nháp.'
        end
        format.turbo_stream do
          render partial: 'manage/courses/course_stream', formats: [:turbo_stream],
                 locals: { courses: @courses, message: "#{count} khóa học đã được cập nhật thành bản nháp.", flash_type: 'success' }
        end
      end
    end

    def bulk_delete
      courses = Course.where(id: params[:course_ids])
      count = courses.count
      course_ids = courses.pluck(:id)
      courses.destroy_all

      respond_to do |format|
        format.html do
          redirect_to manage_courses_path, notice: 'khóa học đã được xóa thành công.'
        end
        format.turbo_stream do
          render partial: 'manage/courses/course_stream', formats: [:turbo_stream],
                 locals: { courses: Course.where(id: course_ids), message: "#{count} khóa học đã được xóa", flash_type: 'success', action: 'delete' }
        end
      end
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def set_categories
      @categories = Category.all.order(:name)
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
