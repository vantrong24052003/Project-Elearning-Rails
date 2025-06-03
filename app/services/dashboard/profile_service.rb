# frozen_string_literal: true

class Dashboard::ProfileService
  def initialize(user)
    @user = user
  end

  def load_user_data
    if @user.has_role?(:admin) || @user.has_role?(:instructor)
      {
        courses: @user.courses.includes(:categories),
        enrollments: nil
      }
    else
      {
        courses: nil,
        enrollments: @user.enrollments.includes(course: :categories).where(status: 'active')
      }
    end
  end
end 