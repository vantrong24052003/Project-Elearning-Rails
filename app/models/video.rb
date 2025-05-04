# frozen_string_literal: true

class Video < ApplicationRecord
  belongs_to :lesson
  belongs_to :upload
  has_many :video_progresses, dependent: :destroy
  has_many :watched_users, through: :video_progresses, source: :user

  validates :title, presence: true
  enumerize :moderation_status, in: %i[pending approved rejected locked], default: :pending, predicates: true, scope: true
end
