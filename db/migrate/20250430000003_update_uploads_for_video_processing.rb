# frozen_string_literal: true

class UpdateUploadsForVideoProcessing < ActiveRecord::Migration[8.0]
  def change
    add_column :uploads, :formats, :string, array: true, default: []
    add_column :uploads, :progress, :integer, default: 0
    add_column :uploads, :filename, :string
    add_column :uploads, :moderation_status, :string, default: 'pending'
    add_column :uploads, :processing_log, :text
  end
end
