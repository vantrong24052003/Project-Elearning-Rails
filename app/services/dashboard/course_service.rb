# frozen_string_literal: true

class Dashboard::CourseService
  def initialize(current_user)
    @current_user = current_user
  end

  def filter_and_paginate_courses(params)
    courses = base_courses
    courses = apply_search_filter(courses, params[:search])
    courses = apply_category_filter(courses, params[:category_id])
    courses = apply_price_filters(courses, params[:min_price], params[:max_price])
    courses = apply_sort(courses, params[:sort_by])

    courses.page(params[:page]).per(12)
  end

  def calculate_course_statistics(course, videos, enrollments)
    {
      total_duration: calculate_total_duration(videos),
      active_students_count: calculate_active_students(enrollments)
    }
  end

  def get_related_courses(course)
    Course.published
          .joins(:course_categories)
          .where(course_categories: { category_id: course.category_ids })
          .where.not(id: course.id)
          .distinct
          .limit(3)
  end

  private

  def base_courses
    if @current_user&.has_role?(:instructor)
      @current_user.courses.where(status: :published)
    else
      Course.where(status: :published)
    end
  end

  def apply_search_filter(courses, search_term)
    return courses unless search_term.present?

    courses.where('title ILIKE ?', "%#{search_term}%")
  end

  def apply_category_filter(courses, category_id)
    return courses unless category_id.present? && category_id != 'all_categories'

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

  def calculate_total_duration(videos)
    total_duration = 0

    videos.each do |video|
      total_duration += video.upload.duration if video.upload&.duration
    end

    total_duration
  end

  def calculate_active_students(enrollments)
    enrollments.where(status: :active).count
  end
end 