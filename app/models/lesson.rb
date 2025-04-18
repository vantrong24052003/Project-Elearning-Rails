class Lesson < ApplicationRecord
  # Associations
  belongs_to :chapter
  has_many :videos

  # Validations
  validates :title, :description, :position, presence: true
end
