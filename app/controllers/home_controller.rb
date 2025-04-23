# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @featured_courses = Course.where(status: 'published')
                              .includes(:user)
                              .order(created_at: :desc)
                              .limit(4)

    @categories = Category.all.limit(8)

    @course_categories = CourseCategory.includes(:category)
                                       .where(course_id: @featured_courses.pluck(:id))
                                       .group_by(&:course_id)
  end
end
