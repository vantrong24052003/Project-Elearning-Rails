# frozen_string_literal: true

class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos, id: :uuid do |t|
      t.string :title
      t.date :is_locked
      t.references :lesson, null: false, foreign_key: true, type: :uuid
      t.references :upload, null: false, foreign_key: true, type: :uuid
      t.string :moderation_status, default: 'pending'
      t.timestamps
    end
  end
end
