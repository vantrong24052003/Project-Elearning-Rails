# frozen_string_literal: true

class Manage::OverviewsController < Manage::BaseController
  def index
    service = Manage::OverviewService.new(current_user)
    if current_user.has_role?(:admin)
      data = service.admin_data
      @total_courses = data[:total_courses]
      @total_students = data[:total_students]
      @total_instructors = data[:total_instructors]
      @total_enrollments = data[:total_enrollments]
      @total_completed_courses = data[:total_completed_courses]
      @total_active_courses = data[:total_active_courses]
      @course_ratings = data[:course_ratings]
      @course_categories = data[:course_categories]
      @monthly_enrollments = data[:monthly_enrollments]
      @monthly_completed_courses = data[:monthly_completed_courses]
    elsif current_user.has_role?(:instructor)
      data = service.instructor_data
      @instructor_courses = data[:instructor_courses]
      @instructor_students = data[:instructor_students]
      @instructor_revenue = data[:instructor_revenue]
      @instructor_rating = data[:instructor_rating]
      @instructor_total_enrollments = data[:instructor_total_enrollments]
      @instructor_completed_courses = data[:instructor_completed_courses]
      @instructor_active_courses = data[:instructor_active_courses]
      @instructor_recent_courses = data[:instructor_recent_courses]
      @instructor_recent_enrollments = data[:instructor_recent_enrollments]
      @instructor_monthly_revenue = data[:instructor_monthly_revenue]
      @instructor_monthly_enrollments = data[:instructor_monthly_enrollments]
    end
  end
end
