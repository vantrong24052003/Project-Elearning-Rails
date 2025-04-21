# frozen_string_literal: true

module Manage
  class DashboardController < Manage::BaseController
    def index
      @total_users = User.count
      @total_courses = Course.count
      @total_enrollments = 0
      @total_revenue = 0
    end
  end
end
