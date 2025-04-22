class Category < ApplicationRecord
  # Associations
  has_many :course_categories
  has_many :courses, through: :course_categories

  # Validations
  validates :name, :description, presence: true
end
