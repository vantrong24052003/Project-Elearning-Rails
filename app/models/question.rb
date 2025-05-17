# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :course
  belongs_to :user

  has_many :quiz_questions
  has_many :quizzes, through: :quiz_questions

  enumerize :learning_goal, in: %i[remember understand apply analyze create other], default: :other
  enumerize :topic, in: %i[math physics chemistry biology history geography literature programming other],
                    default: :other
  enumerize :difficulty, in: %i[easy medium hard]

  validates :content, :options, :correct_option, :explanation, :difficulty, presence: true
end
