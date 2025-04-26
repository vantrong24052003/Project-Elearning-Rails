# frozen_string_literal: true

  class Manage::DashboardController < Manage::BaseController
    def index
      @total_users = User.count
      @total_courses = Course.count
      @total_enrollments = Enrollment.count if defined?(Enrollment)
      @recent_courses = Course.order(created_at: :desc).limit(5)
    end
end
