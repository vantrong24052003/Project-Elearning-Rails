# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can :read, Course

    can [:create, :index], :payment do |_, course_id|
      course = Course.find_by(id: course_id)
      course && !user.enrollments.where(course: course, status: :active).exists?
    end

    can :payment, Course do |course|
      !user.enrollments.where(course: course, status: :active).exists?
    end

    can :create_payment, Course do |course|
      !user.enrollments.where(course: course, status: :active).exists?
    end

    can :view_payment, Course do |course|
      !user.enrollments.where(course: course, status: :active).exists?
    end

    can :course_viewer, Course do |course|
      course.enrollments.exists?(user: user, status: :active)
    end

    can :read, Quiz do |quiz|
      quiz.course.enrollments.exists?(user: user, status: :active)
    end

    if user.has_role?(:instructor)
      can %i[read create update destroy], Course, user_id: user.id
      can :read, Quiz, course: { user_id: user.id }
    end

    return unless user.has_role?(:admin)

    can :manage, :all
  end
end
