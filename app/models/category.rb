# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :course_categories
  has_many :courses, through: :course_categories

  validates :name, :description, presence: true
end
