# frozen_string_literal: true

class CreateVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :videos do |t|
      t.string :title
      t.date :is_locked
      t.references :lesson, null: false, foreign_key: true
      t.references :upload, null: false, foreign_key: true

      t.timestamps
    end
  end
end
