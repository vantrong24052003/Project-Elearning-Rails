  # frozen_string_literal: true

  class Dashboard::CoursesController < Dashboard::DashboardController
    before_action :set_course, only: %i[show edit update destroy publish unpublish]

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

      @courses = courses.page(params[:page]).per(10).accessible_by(current_ability)

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
      @course.update(status: :published)
      redirect_to dashboard_course_path(@course), notice: 'Course has been published.'
    end

    def unpublish
      @course.update(status: :draft)
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
