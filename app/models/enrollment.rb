# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: 'already enrolled in this course' }
  validates :payment_code, uniqueness: true, allow_nil: true

  enumerize :status, in: %i[pending active completed], default: :pending, predicates: true, scope: true
  enumerize :payment_method, in: %i[bank_transfer credit_card e_wallet], predicates: true, scope: true

  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }
end
