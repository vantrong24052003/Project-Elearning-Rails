# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :course
  belongs_to :user

  has_many :quiz_questions
  has_many :quizzes, through: :quiz_questions
  validates :content, :options, :correct_option, :explanation, :difficulty, presence: true
end
