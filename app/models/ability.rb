# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    guest_abilities
    return unless user.present?

    user_abilities(user)

    student_abilities(user) if user.has_role?(:student)
    instructor_abilities(user) if user.has_role?(:instructor)
    admin_abilities(user) if user.has_role?(:admin)
  end

  private

  def guest_abilities
    can :read, :pages

    can :read, Course, status: 'published'
    can %i[search categories], Course
    can :read, Category

    cannot :access, :dashboard
  end

  def user_abilities(user)
    can %i[read edit update], User, id: user.id
    can :change_password, User, id: user.id
    can :manage, :profile, id: user.id

    can :access, :dashboard

    can :read, Course, status: 'published'
    can %i[search categories], Course
    can :read, Category
    can :read, Chapter, course: { status: 'published' }
    can :read, Lesson, chapter: { course: { status: 'published' } }
  end

  def student_abilities(user)
    can :enroll, Course, status: 'published'
    can :read, Enrollment, user_id: user.id

    can :access, Course do |course|
      Progress.exists?(user_id: user.id, course_id: course.id)
    end

    can :read, Chapter do |chapter|
      Progress.exists?(user_id: user.id, course_id: chapter.course_id)
    end

    can :read, Lesson do |lesson|
      Progress.exists?(user_id: user.id, course_id: lesson.chapter.course_id)
    end

    can :watch, Video do |video|
      Progress.exists?(user_id: user.id, course_id: video.lesson.chapter.course_id) &&
        (video.is_locked.nil? || video.is_locked <= Date.today)
    end

    can :manage, Progress, user_id: user.id

    can :attempt, Quiz do |quiz|
      Progress.exists?(user_id: user.id, course_id: quiz.course_id)
    end
    can :read, QuizAttempt, user_id: user.id

    can :read, :certificate, user_id: user.id

    can :create, :review do |_review, course|
      Progress.exists?(user_id: user.id, course_id: course.id)
    end
    can %i[update destroy], :review, user_id: user.id
  end

  def instructor_abilities(user)
    can :access, :instructor_dashboard

    can :manage, Course, user_id: user.id
    can %i[publish unpublish], Course, user_id: user.id

    can :manage, Chapter, course: { user_id: user.id }
    can :manage, Lesson, chapter: { course: { user_id: user.id } }

    can :read, :student do |student, course|
      course.user_id == user.id &&
        Progress.exists?(user_id: student.id, course_id: course.id)
    end

    can :read, :analytics, course: { user_id: user.id }

    can :manage, Quiz, course: { user_id: user.id }
    can :manage, Question, course: { user_id: user.id }
    can :read, QuizAttempt, quiz: { course: { user_id: user.id } }

    can :manage, Upload, user_id: user.id

    can :manage, Video, lesson: { chapter: { course: { user_id: user.id } } }

    can :read, :review, course: { user_id: user.id }
    can :respond_to, :review, course: { user_id: user.id }

    can :read, Enrollment, course: { user_id: user.id }

    can :read, Progress, course: { user_id: user.id }
  end

  def admin_abilities(user)
    can :manage, :all

    can :access, :admin_dashboard

    can :manage, User
    can :assign_roles, User

    can :manage, Category

    can :manage, :settings

    can %i[approve reject feature], Course

    can :access, :dashboard_admin_users
    can :access, :dashboard_admin_categories
    can :access, :dashboard_admin_settings

    cannot :destroy, User, id: user.id
  end
end
