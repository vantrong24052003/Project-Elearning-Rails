# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :course
  has_many :lessons

  validates :title, :position, presence: true
end
