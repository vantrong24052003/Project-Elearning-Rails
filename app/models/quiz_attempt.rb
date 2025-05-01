# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

  validates :score, presence: true

  serialize :answers, coder: JSON

  def correct_answers
    correct_count = 0
    return correct_count if answers.blank?

    answers.each do |question_id, answer|
      question = Question.find_by(id: question_id)
      correct_count += 1 if question && answer.to_i == question.correct_option
    end
    correct_count
  end

  def correct_answer?(question_id)
    if answers.blank? || !answers.key?(question_id.to_s)
      return false
    end

    question = Question.find_by(id: question_id)
    if question.nil?
      return false
    end

    answers[question_id.to_s].to_i == question.correct_option
  end
end
