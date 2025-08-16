# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

  validates :score, presence: true

  serialize :answers, coder: JSON

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_course, ->(course_id) { joins(:quiz).where(quizzes: { course_id: course_id }) }
  scope :practice, -> { joins(:quiz).where(quizzes: { is_exam: false }) }
  scope :exam, -> { joins(:quiz).where(quizzes: { is_exam: true }) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where(completed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :best_scores, lambda {
    select('user_id, MAX(score) as best_score, COUNT(*) as attempts_count, MAX(created_at) as last_attempt_at').group(:user_id)
  }
  scope :suspicious, -> { where(suspicious: true) }
  scope :auto_submitted, -> { where(auto_submitted: true) }

  def correct_answers
    correct_count = 0
    return correct_count if answers.blank?

    parsed_answers = answers_hash
    parsed_answers.each do |question_id, answer|
      question = Question.find_by(id: question_id)
      correct_count += 1 if question && answer.to_i == question.correct_option
    end
    correct_count
  end

  def correct_answer?(question_id)
    return false if answers.blank?

    parsed_answers = answers_hash
    return false unless parsed_answers.key?(question_id.to_s)
    return false unless parsed_answers.key?(question_id.to_s)

    question = Question.find_by(id: question_id)
    return false if question.nil?

    parsed_answers[question_id.to_s].to_i == question.correct_option
  end

  def log_action(details = {})
    current_logs = log_actions || []
    log_entry = { timestamp: Time.current, client_ip: details[:client_ip] || '',
                  device_info: details[:device_info] || '' }

    log_entry.merge!(details) if details.present?

    current_logs << log_entry
    update(log_actions: current_logs)
  end

  def answers_hash
    return {} if answers.blank?
    return JSON.parse(answers) if answers.is_a?(String)

    answers
  end

  def exceeds_cheating_threshold?
    tab_switch_count >= QuizThresholds::DEFAULT_TAB_SWITCH_THRESHOLD ||
      copy_paste_count >= QuizThresholds::DEFAULT_COPY_PASTE_THRESHOLD ||
      screenshot_count >= QuizThresholds::DEFAULT_SCREENSHOT_THRESHOLD ||
      devtools_open_count >= QuizThresholds::DEFAULT_DEVTOOLS_THRESHOLD ||
      device_count >= QuizThresholds::DEFAULT_DEVICE_THRESHOLD
  end

  def should_auto_submit?
    quiz.exam? && exceeds_cheating_threshold?
  end

  def mark_suspicious!(reason = nil)
    log_entry = { action: 'marked_suspicious', reason: reason, timestamp: Time.current }
    log_action(log_entry)
    update!(suspicious: true)
  end

  def auto_submit_for_cheating!
    return false if completed_at.present?

    score_result = calculate_current_score

    update!(
      score: score_result[:score],
      completed_at: Time.current,
      auto_submitted: true,
      suspicious: true
    )

    log_action({ action: 'auto_submitted', reason: 'cheating_detected', final_score: score_result[:score] })
    true
  end

  private

  def calculate_current_score
    return { score: 0, correct_count: 0 } if answers.blank?

    questions_map = quiz.questions.includes(:quiz_questions).index_by { |q| q.id.to_s }
    parsed_answers = answers_hash

    correct_count = parsed_answers.count do |question_id, user_answer|
      question = questions_map[question_id]
      question && question.correct_option == user_answer.to_i
    end

    total_questions = quiz.questions.count
    score = total_questions.positive? ? (correct_count.to_f / total_questions * 10).round(1) : 0

    { score: score, correct_count: correct_count, total_questions: total_questions }
  end
end
