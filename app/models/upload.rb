# frozen_string_literal: true

class Upload < ApplicationRecord
  belongs_to :user

  validates :file_type, :cdn_url, :thumbnail_path, :duration, :resolution, presence: true

  enumerize :status, in: %i[pending processing success failed], default: :pending, predicates: true, scope: true
end
