# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :chapter
  has_many :videos, dependent: :destroy
  has_many :progresses, dependent: :destroy
  has_many :completed_by_users, -> { joins(:progresses).where(progresses: { status: :done }) },
           through: :progresses,
           source: :user

  validates :title, :description, :position, presence: true
end
