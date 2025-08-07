# frozen_string_literal: true

class Course < ApplicationRecord
  belongs_to :user
  has_many :chapters
  has_many :lessons, through: :chapters
  has_many :questions
  has_many :course_categories
  has_many :categories, through: :course_categories
  has_many :quizzes, dependent: :destroy

  has_many :enrollments, dependent: :destroy
  has_many :enrolled_users, through: :enrollments, source: :user
  has_many :enrolled_students, through: :enrollments, source: :user

  has_many :payments, class_name: :Enrollment, foreign_key: :course_id
  validates :title, :description, :price, :thumbnail_path, :language, :status, presence: true

  enumerize :status, in: %i[draft published], predicates: true, scope: true, default: :draft

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }

  scope :search_title, ->(term) { term.present? ? where('title ILIKE ?', "%#{term}%") : all }
  scope :in_category, lambda { |category_id|
    category_id.present? && category_id != 'all_categories' ? joins(:course_categories).where(course_categories: { category_id: category_id }) : all
  }
  scope :price_min, ->(min) { min.present? ? where('price >= ?', min.to_i) : all }
  scope :price_max, ->(max) { max.present? ? where('price <= ?', max.to_i) : all }
  scope :sorted_by, lambda { |sort_by|
    case sort_by
    when 'price_low'
      order(price: :asc, id: :asc)
    when 'price_high'
      order(price: :desc, id: :desc)
    when 'newest'
      order(created_at: :desc, id: :desc)
    else
      order(created_at: :desc, id: :desc)
    end
  }
end
