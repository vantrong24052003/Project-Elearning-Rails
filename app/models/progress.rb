class Progress < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :course
  belongs_to :lesson

  # Validations
  validates :status, presence: true
end
