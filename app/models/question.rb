class Question < ApplicationRecord
  # Associations
  belongs_to :course
  belongs_to :user

  has_many :quiz_questions
  # Validations
  validates :content, :options, :correct_option, :explanation, :difficulty, presence: true
end
