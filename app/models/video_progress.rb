# frozen_string_literal: true

class VideoProgress < ApplicationRecord
  belongs_to :user
  belongs_to :video

  validates :user_id, uniqueness: { scope: :video_id }
end
