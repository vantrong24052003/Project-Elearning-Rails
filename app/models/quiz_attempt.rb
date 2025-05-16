# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

  validates :score, presence: true

  serialize :answers, coder: JSON

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
    log_entry = {
      timestamp: Time.current,
      client_ip: details[:client_ip] || '',
      device_info: details[:device_info] || ''
    }

    log_entry.merge!(details) if details.present?

    current_logs << log_entry
    update(log_actions: current_logs)
  end

  def answers_hash
    return {} if answers.blank?
    return JSON.parse(answers) if answers.is_a?(String)

    answers
  end
end
