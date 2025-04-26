# frozen_string_literal: true

class Video < ApplicationRecord
  belongs_to :lesson
  belongs_to :upload
  has_many :video_progresses, dependent: :destroy
  has_many :watched_users, through: :video_progresses, source: :user

  validates :title, presence: true
end
