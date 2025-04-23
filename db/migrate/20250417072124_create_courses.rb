# frozen_string_literal: true

class CreateCourses < ActiveRecord::Migration[8.0]
  def change
    create_table :courses do |t|
      t.string :title
      t.text :description
      t.decimal :price
      t.string :thumbnail_path
      t.string :language
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
