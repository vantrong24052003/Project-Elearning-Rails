# frozen_string_literal: true

class QuizQuestion < ApplicationRecord
  # Associations
  belongs_to :quiz
  belongs_to :question
end
