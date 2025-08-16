# frozen_string_literal: true

class SendCheatingAlertJob < ApplicationJob
  queue_as :default

  def perform(quiz_attempt_id)
    quiz_attempt = QuizAttempt.find(quiz_attempt_id)
    quiz = quiz_attempt.quiz
    course = quiz.course
    student = quiz_attempt.user
    instructor = course.user

    CourseMailer.cheating_notification(instructor, quiz_attempt).deliver_now
    CourseMailer.cheating_notification(student, quiz_attempt).deliver_now

    quiz_attempt.update!(notified_at: Time.current)
  end
end
