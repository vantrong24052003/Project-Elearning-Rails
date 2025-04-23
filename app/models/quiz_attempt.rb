# frozen_string_literal: true

class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user

  validates :score, presence: true
end
