# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # All users
    can :read, Course, status: :published

    return if user.blank?

    # All logged in
    can :read, Course, status: :published
    can :read, Course, user_id: user.id
    can :read, Course, enrollments: { user_id: user.id }

    # Student
    can :read, Chapter, course: { enrollments: { user_id: user.id } }
    can :read, Lesson, chapter: { course: { enrollments: { user_id: user.id } } }
    can :read, Video, lesson: { chapter: { course: { enrollments: { user_id: user.id } } } }

    can :read, Quiz, course: { enrollments: { user_id: user.id } }
    can :attempt, Quiz, course: { enrollments: { user_id: user.id } }
    can :create, QuizAttempt, user_id: user.id
    can :read, QuizAttempt, user_id: user.id

    # Enrollment
    can :create, Enrollment, user_id: user.id
    can :read, Enrollment, user_id: user.id

    # Instructor
    if user.has_role?(:instructor)
      can :manage, Course, user_id: user.id
      can :publish, Course, user_id: user.id
      can :unpublish, Course, user_id: user.id

      can :manage, Chapter, course: { user_id: user.id }
      can :manage, Lesson, chapter: { course: { user_id: user.id } }
      can :manage, Video, lesson: { chapter: { course: { user_id: user.id } } }

      can :manage, Quiz, course: { user_id: user.id }
      can :manage, Question, course: { user_id: user.id }

      can :manage, Upload, user_id: user.id

      can :read, QuizAttempt, quiz: { course: { user_id: user.id } }

      # Enrollment
      can :read, Enrollment, course: { user_id: user.id }
      can :update, Enrollment, course: { user_id: user.id }
    end

    return unless user.has_role?(:admin)

    can :manage, :all
  end
end
