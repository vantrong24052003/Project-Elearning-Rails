# frozen_string_literal: true

module Manage
  class DashboardController < Manage::BaseController
    def index
      @total_users = User.count
      @total_courses = Course.count
      @total_published_courses = Course.where(status: 'published').count
      @total_draft_courses = Course.where(status: 'draft').count

      @total_enrollments = defined?(Enrollment) ? Enrollment.count : 0

      @total_revenue = defined?(Order) ? Order.where(status: 'completed').sum(:total) : 0
    end
  end
end
