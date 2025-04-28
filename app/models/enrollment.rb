# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: 'already enrolled in this course' }
  validates :payment_code, uniqueness: true, allow_nil: true

  enumerize :status, in: %i[pending active completed], default: :pending, predicates: true, scope: true

  scope :active, -> { where(status: :active) }
  scope :pending, -> { where(status: :pending) }
  scope :completed, -> { where(status: :completed) }

  # Trạng thái hoàn thành
  def completed?
    # Logic xác định khóa học đã hoàn thành
    # Ví dụ: progress >= 100 hoặc completed_at.present?
    progress.to_i >= 100 || completed_at.present?
  end
end
