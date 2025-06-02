# frozen_string_literal: true

class Dashboard::CoursesController < Dashboard::DashboardController
  before_action :set_course, only: %i[show edit update destroy]

  def index
    @categories = Category.all

    courses = base_courses
    courses = apply_search_filter(courses, params[:search])
    courses = apply_category_filter(courses, params[:category_id])
    courses = apply_price_filters(courses, params[:min_price], params[:max_price])
    courses = apply_sort(courses, params[:sort_by])

    @courses = courses.page(params[:page]).per(12)

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

    @can_view_full_content = if current_user&.has_role?(:admin) || @course.user_id == current_user&.id
                               true
                             elsif current_user
                               @enrollments.exists?(user_id: current_user.id, status: :active)
                             else
                               false
                             end

    set_course_statistics
    set_user_progress if user_enrolled?
    set_related_courses
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

  private

  def base_courses
    if current_user&.has_role?(:instructor)
      current_user.courses
    else
      Course.all
    end
  end

  def apply_search_filter(courses, search_term)
    return courses unless search_term.present?

    courses.where('title ILIKE ?', "%#{search_term}%")
  end

  def apply_category_filter(courses, category_id)
    return courses unless category_id.present?

    courses.joins(:course_categories).where(course_categories: { category_id: category_id })
  end

  def apply_price_filters(courses, min_price, max_price)
    result = courses

    result = result.where('price >= ?', min_price.to_i) if min_price.present?

    result = result.where('price <= ?', max_price.to_i) if max_price.present?

    result
  end

  def apply_sort(courses, sort_by)
    case sort_by
    when 'newest'
      courses.order(created_at: :desc)
    when 'price_low'
      courses.order(price: :asc)
    when 'price_high'
      courses.order(price: :desc)
    else
      courses.order(created_at: :desc)
    end
  end

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
      total_duration += video.upload.duration if video.upload&.duration
    end

    total_duration
  end

  def calculate_active_students
    @enrollments.where(status: :active).count
  end

  def user_enrolled?
    return true if current_user&.has_role?(:admin)
    return true if @course.user_id == current_user&.id

    current_user && @enrollments.exists?(user_id: current_user.id, status: :active)
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
end
