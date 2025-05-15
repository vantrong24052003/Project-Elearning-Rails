# frozen_string_literal: true

class Upload < ApplicationRecord
  attr_accessor :video

  belongs_to :user

  validates :cdn_url, :thumbnail_path, presence: true, on: :update, if: :success?

  enumerize :status, in: %i[pending processing success failed], default: :pending, predicates: true, scope: true
  enumerize :transcription_status, in: %i[pending processing completed failed], predicates: true, scope: true

  after_update :start_transcription, if: :should_start_transcription?

  private

  def start_transcription
    TranscribeJob.perform_later(id)
  end

  def should_start_transcription?
    saved_change_to_status? &&
    status == 'success' &&
    transcription.blank? &&
    cdn_url.present? &&
    !cdn_url.include?('placeholder')
  end
end
