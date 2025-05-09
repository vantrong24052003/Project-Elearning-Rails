# frozen_string_literal: true

class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses, id: :uuid do |t|
      t.string :title
      t.text :description
      t.decimal :price
      t.string :thumbnail_path
      t.string :language
      t.string :status
      t.string :demo_video_path
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.boolean :is_free, default: false

      t.timestamps
    end
  end
end
