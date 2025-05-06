# frozen_string_literal: true

class Upload < ApplicationRecord
  attr_accessor :video

  belongs_to :user

  validates :cdn_url, :thumbnail_path, presence: true, on: :update, if: :success?

  enumerize :status, in: %i[pending processing success failed], default: :pending, predicates: true, scope: true
end
