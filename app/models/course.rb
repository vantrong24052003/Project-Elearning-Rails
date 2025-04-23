# frozen_string_literal: true

class Course < ApplicationRecord
  belongs_to :user
  has_many :chapters
  has_many :questions
  has_many :course_categories
  has_many :categories, through: :course_categories

  validates :title, :description, :price, :thumbnail_path, :language, :status, presence: true

  scope :search_by_params, lambda { |params|
    courses = all

    courses = courses.where('LOWER(title) LIKE ?', "%#{params[:query].downcase}%") if params[:query].present?

    courses = courses.where(status: params[:status]) if params[:status].present?

    if params[:category_id].present?
      courses = courses.joins(:course_categories).where(course_categories: { category_id: params[:category_id] })
    end

    if params[:price_type] == 'free'
      courses = courses.where('price = 0 OR price IS NULL')
    elsif params[:price_type] == 'paid'
      courses = courses.where('price > 0')
    end

    courses = courses.where(user_id: params[:user_id]) if params[:user_id].present?

    courses
  }
end
