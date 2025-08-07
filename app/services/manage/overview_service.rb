# frozen_string_literal: true

class Manage::OverviewService
  def initialize(current_user)
    @current_user = current_user
  end

  def admin_data
    {
      total_courses: Course.count,
      total_students: User.joins(:roles).where(roles: { name: :student }).count,
      total_instructors: User.joins(:roles).where(roles: { name: :instructor }).count,
      total_enrollments: Enrollment.count,
      total_completed_courses: Enrollment.where.not(completed_at: nil).count,
      total_active_courses: Course.where(status: :published).count,
      course_ratings: Course.where.not(rating: nil).order(rating: :desc).limit(5),
      course_categories: Category.joins(:courses).group('categories.name').count,
      monthly_enrollments: monthly_data('enrolled_at'),
      monthly_completed_courses: monthly_data('completed_at', true)
    }
  end

  def instructor_data
    courses = Course.where(user_id: @current_user.id)
    course_ids = courses.pluck(:id)
    enrollments = Enrollment.where(course_id: course_ids)
    active_enrollments = enrollments.where(status: :active)

    {
      instructor_courses: courses,
      instructor_students: User.joins(:enrollments)
                              .where(enrollments: { course_id: course_ids })
                              .distinct
                              .count,
      instructor_revenue: active_enrollments.sum(:amount),
      instructor_rating: courses.average(:rating),
      instructor_total_enrollments: enrollments.count,
      instructor_completed_courses: enrollments.where.not(completed_at: nil).count,
      instructor_active_courses: courses.where(status: :published).count,
      instructor_recent_courses: courses.includes(:categories).order(created_at: :desc).limit(5),
      instructor_recent_enrollments: enrollments.includes(:user, :course)
                                              .order(created_at: :desc)
                                              .limit(5),
      instructor_monthly_revenue: monthly_revenue(course_ids),
      instructor_monthly_enrollments: monthly_enrollments(course_ids)
    }
  end

  private

  def monthly_data(date_field, completed = false)
    query = Enrollment.where("#{date_field} >= ?", 6.months.ago)
    query = query.where.not(completed_at: nil) if completed
    query.group("DATE_TRUNC('month', #{date_field})")
         .count
         .transform_keys { |k| k.strftime('%Y-%m') }
  end

  def monthly_revenue(course_ids)
    Enrollment.where(course_id: course_ids)
              .where(status: :active)
              .where('paid_at >= ?', 6.months.ago)
              .group("DATE_TRUNC('month', paid_at)")
              .sum(:amount)
              .transform_keys { |k| k.strftime('%Y-%m') }
  end

  def monthly_enrollments(course_ids)
    Enrollment.where(course_id: course_ids)
              .where('enrolled_at >= ?', 6.months.ago)
              .group("DATE_TRUNC('month', enrolled_at)")
              .count
              .transform_keys { |k| k.strftime('%Y-%m') }
  end
end 