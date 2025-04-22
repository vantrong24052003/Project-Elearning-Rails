# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :chapter
  has_many :videos

  validates :title, :description, :position, presence: true
end
