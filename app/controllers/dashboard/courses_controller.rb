# frozen_string_literal: true

module Dashboard
  class CoursesController < Dashboard::DashboardController
    before_action :set_course, only: %i[show edit update destroy publish unpublish]

    def index
      @categories = Category.all

      # Apply filters
      courses = if current_user.has_role?(:instructor)
                  # For instructors, show only their created courses
                  current_user.courses
                else
                  # For regular users, show all available courses
                  Course.all
                end

      # Search
      courses = courses.where("title ILIKE ?", "%#{params[:search]}%") if params[:search].present?

      # Category filter
      courses = courses.joins(:course_categories).where(course_categories: { category_id: params[:category_id] }) if params[:category_id].present?

      # Price range filter
      courses = courses.where("price >= ?", params[:min_price]) if params[:min_price].present?
      courses = courses.where("price <= ?", params[:max_price]) if params[:max_price].present?

      # Status filter - only show published courses to students
      courses = courses.where(status: 'published') unless current_user.has_role?(:instructor) || current_user.has_role?(:admin)

      # Sort
      case params[:sort_by]
      when "newest"
        courses = courses.order(created_at: :desc)
      when "price_low"
        courses = courses.order(price: :asc)
      when "price_high"
        courses = courses.order(price: :desc)
      else
        courses = courses.order(created_at: :desc)
      end

      @courses = courses.page(params[:page]).per(12) # Increased to 12 for 4 columns x 3 rows

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      @chapters = @course.chapters.includes(:lessons).order(:position)
      @enrollments = @course.enrollments.includes(:user).order(created_at: :desc).limit(10)
      @reviews = @course.reviews.includes(:user).order(created_at: :desc)
      @average_rating = @course.average_rating
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
      @course.update(status: 'published')
      redirect_to dashboard_course_path(@course), notice: 'Course has been published.'
    end

    def unpublish
      @course.update(status: 'draft')
      redirect_to dashboard_course_path(@course), notice: 'Course has been unpublished.'
    end

    private

    def set_course
      @course = Course.find(params[:id])
    end

    def course_params
      params.require(:course).permit(
        :title, :description, :price, :thumbnail_path, :language,
        :status, category_ids: []
      )
    end
  end
end
