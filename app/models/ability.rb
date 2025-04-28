# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    can :read, Course

    can [:payment, :demo_success], Course do |course|
      !course.enrollments.exists?(user: user, status: :active)
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
