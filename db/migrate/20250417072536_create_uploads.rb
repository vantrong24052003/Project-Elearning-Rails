# frozen_string_literal: true

class CreateUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :uploads do |t|
      t.string :file_type
      t.string :cdn_url
      t.string :thumbnail_path
      t.integer :duration
      t.string :resolution
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
