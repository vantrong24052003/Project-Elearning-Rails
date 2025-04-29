# frozen_string_literal: true

class Course < ApplicationRecord
  belongs_to :user
  has_many :chapters
  has_many :lessons, through: :chapters
  has_many :questions
  has_many :course_categories
  has_many :categories, through: :course_categories

  has_many :enrollments, dependent: :destroy
  has_many :enrolled_users, through: :enrollments, source: :user
  has_many :enrolled_students, through: :enrollments, source: :user

  validates :title, :description, :price, :thumbnail_path, :language, :status, presence: true

  enumerize :status, in: %i[draft published], predicates: true, scope: true, default: :draft

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: 'draft') }
end
