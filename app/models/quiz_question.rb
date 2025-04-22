class QuizQuestion < ApplicationRecord
  # Associations
  belongs_to :quiz
  belongs_to :question
end
