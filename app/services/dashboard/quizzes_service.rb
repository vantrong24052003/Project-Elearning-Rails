# frozen_string_literal: true

class Dashboard::QuizzesService
  def latest_completed_attempt(quiz, user)
    QuizAttempt.where(quiz: quiz, user: user).where.not(completed_at: nil).order(created_at: :desc).first
  end

  def in_progress_attempt(quiz, user)
    QuizAttempt.where(quiz: quiz, user: user, completed_at: nil).order(created_at: :desc).first
  end

  def start_attempt_if_needed!(quiz, user, client_ip, user_agent)
    QuizAttempt.transaction do
      attempt = QuizAttempt.lock.where(quiz: quiz, user: user, completed_at: nil).order(created_at: :desc).first
      attempt ||= QuizAttempt.create!(quiz: quiz, user: user, start_time: Time.zone.now, score: 0, time_spent: 0)
      attempt.log_action({ client_ip: client_ip, device_info: user_agent })
      attempt
    end
  end
end
