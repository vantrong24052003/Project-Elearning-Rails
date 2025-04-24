# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Mặc định: người dùng chưa đăng nhập chỉ có thể đọc các khóa học đã xuất bản
    can :read, Course, status: 'published'

    return unless user.present? # Dừng nếu user không tồn tại

    # Học viên có thể xem khóa học đã xuất bản và các khóa học đã đăng ký
    can :read, Course, status: 'published'
    can :read, Course, enrollments: { user_id: user.id }

    if user.has_role?(:instructor)
      # Giảng viên có thể quản lý khóa học của họ
      can :manage, Course, user_id: user.id
      # Không thể xóa khóa học đã có người đăng ký
      cannot :destroy, Course do |course|
        course.enrollments.count.positive?
      end
    end

    return unless user.has_role?(:admin)

    # Admin có thể quản lý mọi khóa học
    can :manage, Course
  end
end
