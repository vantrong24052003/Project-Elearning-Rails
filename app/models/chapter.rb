class Chapter < ApplicationRecord
  # Associations
  belongs_to :course
  has_many :lessons

  # Validations
  validates :title, :position, presence: true
end
