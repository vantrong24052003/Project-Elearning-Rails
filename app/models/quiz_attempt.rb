# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  # Associations
  belongs_to :quiz
  belongs_to :user

  # Validations
  validates :score, presence: true
end
