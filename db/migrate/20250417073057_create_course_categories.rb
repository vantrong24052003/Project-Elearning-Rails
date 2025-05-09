# frozen_string_literal: true

class CreateCourseCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :course_categories, id: :uuid do |t|
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
