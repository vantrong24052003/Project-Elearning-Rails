# frozen_string_literal: true

class Quiz < ApplicationRecord
  belongs_to :course
  has_many :quiz_questions
  has_many :questions, through: :quiz_questions

  validates :title, :time_limit, presence: true
end
