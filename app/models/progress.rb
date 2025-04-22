# frozen_string_literal: true

class Progress < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :lesson

  validates :status, presence: true
end
