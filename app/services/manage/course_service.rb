# frozen_string_literal: true

class Manage::CourseService
  def initialize(current_user)
    @current_user = current_user
  end

  def find_courses(params)
    courses = Course.includes(:categories)

    courses = if @current_user.has_role?(:admin)
                courses.all
              else
                courses.where(user_id: @current_user.id)
              end

    courses = apply_filters(courses, params)

    courses.order(created_at: :desc)
           .page(params[:page])
           .per(params[:per_page] || 10)
  end

  def handle_categories(course, category_params)
    if category_params.present?
      selected_categories = category_params.reject(&:blank?).map(&:to_i)

      course.course_categories.where.not(category_id: selected_categories).destroy_all

      selected_categories.each do |category_id|
        course.course_categories.find_or_create_by(category_id: category_id)
      end
    else
      course.course_categories.destroy_all
    end
  end

  def publish_course(course)
    course.update(status: :published)
  end

  def draft_course(course)
    course.update(status: :draft)
  end

  private

  def apply_filters(courses, params)
    courses = courses.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    courses = courses.where(status: params[:status]) if params[:status].present?

    if params[:category_id].present?
      courses = courses.joins(:course_categories)
                       .where(course_categories: { category_id: params[:category_id] })
    end

    courses = courses.where(language: params[:language]) if params[:language].present?
    courses = courses.where('price >= ?', params[:min_price].to_f) if params[:min_price].present?
    courses = courses.where('price <= ?', params[:max_price].to_f) if params[:max_price].present?

    courses
  end
end 