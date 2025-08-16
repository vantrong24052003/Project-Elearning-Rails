# frozen_string_literal: true

class Dashboard::QuizzesService < Dashboard::QuizService
  def in_progress_attempt(quiz, user)
    current_attempt(quiz, user)
  end

  def start_attempt_if_needed!(quiz, user, client_ip, user_agent)
    start_attempt(quiz, user, { client_ip: client_ip, device_info: user_agent })
  end
end
