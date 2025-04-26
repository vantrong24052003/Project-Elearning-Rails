# frozen_string_literal: true

  class Dashboard::CoursesController < Dashboard::DashboardController
    before_action :set_course, only: %i[show edit update destroy publish unpublish course_viewer mark_lesson_completed]
    before_action :authorize_course_viewer!, only: [:course_viewer]

    def index
      @categories = Category.all

      courses = if current_user.has_role?(:instructor)
                  current_user.courses
                else
                  Course.all
                end

      courses = courses.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?

      if params[:category_id].present?
        courses = courses.joins(:course_categories).where(course_categories: { category_id: params[:category_id] })
      end

      courses = courses.where('price >= ?', params[:min_price]) if params[:min_price].present?
      courses = courses.where('price <= ?', params[:max_price]) if params[:max_price].present?

      courses = case params[:sort_by]
                when 'newest'
                  courses.order(created_at: :desc)
                when 'price_low'
                  courses.order(price: :asc)
                when 'price_high'
                  courses.order(price: :desc)
                else
                  courses.order(created_at: :desc)
                end

      @courses = courses.page(params[:page]).per(12).accessible_by(current_ability)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      @course = Course.find(params[:id])
      @chapters = @course.chapters
      @lessons = Lesson.where(chapter_id: @chapters.pluck(:id))
      @videos = Video.includes(:upload).where(lesson_id: @lessons.pluck(:id))
      @enrollments = @course.enrollments

      set_course_statistics
      set_user_progress if user_enrolled?
      set_related_courses
    end

    def add_to_cart
      @course = Course.find(params[:id])
      current_user.cart_items.create(course: @course)

      respond_to do |format|
        format.html { redirect_to dashboard_course_path(@course), notice: 'Đã thêm khóa học vào giỏ hàng' }
        format.turbo_stream { flash.now[:notice] = 'Đã thêm khóa học vào giỏ hàng' }
      end
    end

    def enroll
      @course = Course.find(params[:id])
      current_user.enrollments.create(course: @course, status: :active)

      respond_to do |format|
        format.html { redirect_to course_viewer_dashboard_course_path(@course), notice: 'Đăng ký khóa học thành công' }
        format.turbo_stream { flash.now[:notice] = 'Đăng ký khóa học thành công' }
      end
    end

    def new
      @course = Course.new
      @categories = Category.all
    end

    def create
      @course = current_user.courses.build(course_params)

      if @course.save
        redirect_to dashboard_course_path(@course), notice: 'Course was successfully created.'
      else
        @categories = Category.all
        render :new
      end
    end

    def edit
      @categories = Category.all
    end

    def update
      if @course.update(course_params)
        redirect_to dashboard_course_path(@course), notice: 'Course was successfully updated.'
      else
        @categories = Category.all
        render :edit
      end
    end

    def destroy
      @course.destroy
      redirect_to dashboard_courses_path, notice: 'Course was successfully deleted.'
    end

    def publish
      @course.update(status: :published)
      redirect_to dashboard_course_path(@course), notice: 'Course has been published.'
    end

    def unpublish
      @course.update(status: :draft)
      redirect_to dashboard_course_path(@course), notice: 'Course has been unpublished.'
    end

    def course_viewer
      @course = Course.find(params[:id])

      if request.query_parameters.empty?
        redirect_to course_viewer_dashboard_course_path(@course, lesson_id: 1, video_id: 1)
        return
      end

      @current_lesson = @course.lessons.find_by(id: params[:lesson_id]) if params[:lesson_id]
      @current_video = @current_lesson&.videos&.find_by(id: params[:video_id]) if params[:video_id]

      @course_progress = calculate_course_progress(@course)

      @next_lesson = find_next_lesson if @current_lesson

      @progress = current_user.progresses.find_by(
        course: @course,
        lesson: @current_lesson
      ) if enrolled?
    end

    def mark_lesson_completed
      @course = Course.find(params[:id])
      @lesson = @course.lessons.find(params[:lesson_id])

      @progress = current_user.progresses.find_or_create_by(
        course: @course,
        lesson: @lesson
      )
      @progress.update(status: :done)

      respond_to do |format|
        format.html { redirect_to course_viewer_dashboard_course_path(@course, lesson_id: @lesson.id), notice: 'Đã đánh dấu hoàn thành bài học' }
        format.turbo_stream
      end
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def set_course_statistics
      @total_duration = calculate_total_duration
      @active_students_count = calculate_active_students
    end

    def calculate_total_duration
      total_duration = 0

      @videos.each do |video|
        total_duration += video.upload.duration if video.upload && video.upload.duration
      end

      total_duration
    end

    def calculate_active_students
      @enrollments.where(status: :active).count
    end

    def user_enrolled?
      current_user && @enrollments.exists?(user_id: current_user.id)
    end

    def set_user_progress
      completed_lessons = Progress.where(
        user: current_user,
        course: @course,
        status: :done
      ).count

      @user_progress = {
        completed_lessons: completed_lessons,
        total_lessons: @course.lessons.count
      }
    end

    def set_related_courses
      @related_courses = Course.published
                              .joins(:course_categories)
                              .where(course_categories: { category_id: @course.category_ids })
                              .where.not(id: @course.id)
                              .distinct
                              .limit(3)
    end

    def course_params
      params.permit(
        :title, :description, :price, :thumbnail_path, :language,
        :status, category_ids: []
      )
    end

    def authorize_course_viewer!
      authorize! :course_viewer, @course
    end

    def enrolled?
      return false unless current_user && @course

      current_user.enrollments.active.exists?(course: @course)
    end

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

    def calculate_course_progress(course)
      return {
        completed_lessons: 0,
        total_lessons: 0,
        percentage: 0
      } unless course

      total_lessons = course.lessons.count
      completed_lessons = Progress.where(
        user: current_user,
        course: course,
        status: :done
      ).count

      percentage = total_lessons > 0 ? (completed_lessons.to_f / total_lessons * 100).round : 0

      {
        completed_lessons: completed_lessons,
        total_lessons: total_lessons,
        percentage: percentage
      }
    end
  end
