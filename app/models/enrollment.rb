# frozen_string_literal: true

class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  validates :user_id, uniqueness: { scope: :course_id, message: 'already enrolled in this course' }

  enumerize :status, in: %i[pending active completed cancelled], default: :pending, predicates: true, scope: true
end
