# frozen_string_literal: true

class AddTranscriptionToUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :uploads, :transcription, :text
    add_column :uploads, :transcription_status, :string, default: nil
  end
end
