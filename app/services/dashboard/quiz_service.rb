# frozen_string_literal: true

class Dashboard::QuizService
  def find_quiz_with_questions(quiz_id, user)
    Quiz.includes(:questions, :course).find(quiz_id)
  end

  def can_access_quiz?(quiz, user)
    return true if user.has_role?(:admin)
    return true if user == quiz.course.user
    return true if user && Enrollment.exists?(user: user, course: quiz.course, status: :active)

    false
  end

  def current_attempt(quiz, user)
    quiz.quiz_attempts.where(user: user, completed_at: nil).order(created_at: :desc).first
  end

  def start_attempt(quiz, user, client_info = {})
    QuizAttempt.transaction do
      attempt = quiz.quiz_attempts.lock.where(user: user, completed_at: nil).order(created_at: :desc).first
      attempt ||= quiz.quiz_attempts.create!(user: user, start_time: Time.current, score: 0, time_spent: 0)

      client_ip = client_info[:client_ip] || client_info['client_ip']
      device_info = client_info[:device_info] || client_info['device_info']

      attempt.log_action({ client_ip: client_ip, device_info: device_info })
      attempt
    end
  end

  def submit_attempt(attempt, answers, time_spent)
    raise ActionController::BadRequest, "Already submitted" if attempt.completed_at?

    QuizAttempt.transaction do
      score_result = calculate_score(attempt.quiz, answers)

      attempt.update!(
        answers: answers.to_json,
        score: score_result[:score],
        time_spent: time_spent,
        completed_at: Time.current
      )

      handle_anti_cheating(attempt) if attempt.quiz.exam?

      {
        attempt: attempt,
        results: build_results(attempt, score_result, answers)
      }
    end
  end

  def get_results(attempt)
    if attempt.quiz.exam?
      {
        score: attempt.score,
        auto_submitted: attempt.auto_submitted?,
        suspicious: attempt.suspicious?,
        can_retake: false,
        explanations_shown: false
      }
    else
      {
        score: attempt.score,
        detailed_results: get_detailed_results_from_attempt(attempt),
        can_retake: true,
        explanations_shown: true
      }
    end
  end

  def already_completed?(quiz, user)
    quiz.quiz_attempts.where(user: user).where.not(completed_at: nil).exists?
  end

  def latest_completed_attempt(quiz, user)
    quiz.quiz_attempts.where(user: user).where.not(completed_at: nil).order(created_at: :desc).first
  end

  private

  def calculate_score(quiz, answers)
    questions_map = quiz.questions.includes(:quiz_questions).index_by { |q| q.id.to_s }

    correct_count = answers.count do |question_id, user_answer|
      question = questions_map[question_id.to_s]
      question && question.correct_option == user_answer.to_i
    end

    total_questions = quiz.questions.count
    score = total_questions > 0 ? (correct_count.to_f / total_questions * 10).round(1) : 0

    { score: score, correct_count: correct_count, total_questions: total_questions }
  end

  def build_results(attempt, score_result, answers)
    base_results = {
      score: score_result[:score],
      correct_count: score_result[:correct_count],
      total_questions: score_result[:total_questions]
    }

    if attempt.quiz.practice?
      base_results[:detailed_results] = get_detailed_results(attempt.quiz, answers)
    end

    base_results
  end

  def handle_anti_cheating(attempt)
    return unless attempt.exceeds_cheating_threshold?

    attempt.mark_suspicious!('post_submission_check')

    if attempt.quiz.notify_cheating?
      SendCheatingAlertJob.perform_later(attempt.id)
    end
  end

  def get_detailed_results(quiz, answers)
    questions_map = quiz.questions.includes(:quiz_questions).index_by { |q| q.id.to_s }

    answers.map do |question_id, user_answer|
      question = questions_map[question_id.to_s]
      next unless question

      {
        question_id: question_id,
        question_content: question.content,
        user_answer: user_answer.to_i,
        correct_answer: question.correct_option,
        is_correct: question.correct_option == user_answer.to_i,
        explanation: question.explanation
      }
    end.compact
  end

  def get_detailed_results_from_attempt(attempt)
    return [] unless attempt.answers.present?

    get_detailed_results(attempt.quiz, attempt.answers_hash)
  end
end
