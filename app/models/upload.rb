# frozen_string_literal: true

class Upload < ApplicationRecord
  belongs_to :user

  validates :file_type, :cdn_url, :thumbnail_path, :duration, :resolution, :status, presence: true
end
