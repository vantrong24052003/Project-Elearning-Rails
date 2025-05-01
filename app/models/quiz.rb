# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :course
  has_many :quiz_questions
  has_many :questions, through: :quiz_questions
  has_many :quiz_attempts, dependent: :destroy

  validates :title, :time_limit, presence: true

  def is_exam?
    is_exam
  end
end
