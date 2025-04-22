class Quiz < ApplicationRecord
  # Associations
  belongs_to :course
  has_many :quiz_questions
  has_many :questions, through: :quiz_questions

  # Validations
  validates :title, :time_limit, presence: true
end
