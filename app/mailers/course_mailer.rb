# frozen_string_literal: true

class CourseMailer < ApplicationMailer
  def cheating_notification(user, quiz_attempt)
    @user = user
    @quiz_attempt = quiz_attempt
    @course = quiz_attempt.quiz.course
    @student = quiz_attempt.user

    log_entries = quiz_attempt.log_actions || []
    start_log = log_entries.find { |entry| entry['action'] == 'start_quiz' } || {}

    @device_info = start_log['device_info'] || 'Không xác định'
    @ip_address = start_log['client_ip'] || 'Không xác định'

    mail(
      to: @user.email,
      subject: "Cảnh báo gian lận - #{@course.title} - #{@quiz_attempt.quiz.title}",
      template_path: 'mailers'
    )
  end
end
