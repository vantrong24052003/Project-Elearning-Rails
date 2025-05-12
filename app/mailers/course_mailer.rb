class CourseMailer < ApplicationMailer
  def cheating_notification(user, quiz_attempt)
    @user = user
    @quiz_attempt = quiz_attempt
    @course = quiz_attempt.quiz.course
    @student = quiz_attempt.user

    mail(
      to: @user.email,
      subject: "Cảnh báo gian lận - #{@course.title} - #{@quiz_attempt.quiz.title}",
      template_path: "mailers"
    )
  end
end
