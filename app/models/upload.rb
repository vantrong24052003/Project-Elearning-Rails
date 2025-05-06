# frozen_string_literal: true

class Upload < ApplicationRecord
  attr_accessor :video

  belongs_to :user

  validates :file_type, :cdn_url, :thumbnail_path, :duration, presence: true, on: :update, if: :completed?

  enumerize :status, in: %i[pending processing success failed], default: :pending, predicates: true, scope: true

  def completed?
    status == 'success'
  end

  def quality_url(quality)
    case quality
    when '360p'
      quality_360p_url
    when '480p'
      quality_480p_url
    when '720p'
      quality_720p_url
    end
  end
end
