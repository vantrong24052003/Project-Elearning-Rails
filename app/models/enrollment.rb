# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: 'already enrolled in this course' }

  enumerize :status, in: %i[pending active], default: :pending, predicates: true, scope: true

  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }
end
