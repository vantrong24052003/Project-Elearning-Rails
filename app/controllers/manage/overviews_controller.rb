# frozen_string_literal: true

class Manage::OverviewsController < Manage::BaseController
  def index
    if current_user.has_role?(:admin)
      load_admin_data
    elsif current_user.has_role?(:instructor)
      load_instructor_data
    end
  end

  private

  def load_admin_data
    @total_courses = Course.count
    @total_students = User.joins(:roles).where(roles: { name: :student }).count
    @total_instructors = User.joins(:roles).where(roles: { name: :instructor }).count
    @total_enrollments = Enrollment.count
    @total_completed_courses = Enrollment.where.not(completed_at: nil).count
    @total_active_courses = Course.where(status: :published).count
    @course_ratings = Course.where.not(rating: nil).order(rating: :desc).limit(5)
    @course_categories = Category.joins(:courses).group('categories.name').count
    @monthly_enrollments = Enrollment.where('enrolled_at >= ?', 6.months.ago)
                                     .group("DATE_TRUNC('month', enrolled_at)")
                                     .count
                                     .transform_keys { |k| k.strftime('%Y-%m') }
    @monthly_completed_courses = Enrollment.where.not(completed_at: nil)
                                           .where('completed_at >= ?', 6.months.ago)
                                           .group("DATE_TRUNC('month', completed_at)")
                                           .count
                                           .transform_keys { |k| k.strftime('%Y-%m') }
  end

  def load_instructor_data
    @instructor_courses = Course.where(user_id: current_user.id)
    @instructor_students = User.joins(:enrollments)
                               .where(enrollments: { course_id: @instructor_courses.pluck(:id) })
                               .distinct
                               .count
    @instructor_revenue = Enrollment.where(course_id: @instructor_courses.pluck(:id))
                                    .where(status: :active)
                                    .sum(:amount)
    @instructor_rating = @instructor_courses.average(:rating)
    @instructor_total_enrollments = Enrollment.where(course_id: @instructor_courses.pluck(:id)).count
    @instructor_completed_courses = Enrollment.where(course_id: @instructor_courses.pluck(:id))
                                              .where.not(completed_at: nil)
                                              .count
    @instructor_active_courses = @instructor_courses.where(status: :published).count
    @instructor_recent_courses = @instructor_courses.includes(:categories).order(created_at: :desc).limit(5)
    @instructor_recent_enrollments = Enrollment.includes(:user, :course)
                                               .where(course_id: @instructor_courses.pluck(:id))
                                               .order(created_at: :desc)
                                               .limit(5)
    @instructor_monthly_revenue = Enrollment.where(course_id: @instructor_courses.pluck(:id))
                                            .where(status: :active)
                                            .where('paid_at >= ?', 6.months.ago)
                                            .group("DATE_TRUNC('month', paid_at)")
                                            .sum(:amount)
                                            .transform_keys { |k| k.strftime('%Y-%m') }
    @instructor_monthly_enrollments = Enrollment.where(course_id: @instructor_courses.pluck(:id))
                                                .where('enrolled_at >= ?', 6.months.ago)
                                                .group("DATE_TRUNC('month', enrolled_at)")
                                                .count
                                                .transform_keys { |k| k.strftime('%Y-%m') }
  end
end
