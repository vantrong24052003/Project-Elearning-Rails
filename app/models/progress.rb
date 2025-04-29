# frozen_string_literal: true

class Progress < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :lesson

  validates :user_id, uniqueness: { scope: [:course_id, :lesson_id] }
  enumerize :status, in: %i[pending inprogress done], default: :pending, predicates: true, scope: true
end
