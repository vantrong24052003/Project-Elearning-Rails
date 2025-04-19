# frozen_string_literal: true

class Course < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :chapters
  has_many :questions
  has_many :course_categories
  has_many :categories, through: :course_categories

  # Validations
  validates :title, :description, :price, :thumbnail_path, :language, :status, presence: true
end
