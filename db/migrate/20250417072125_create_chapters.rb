# frozen_string_literal: true

class CreateChapters < ActiveRecord::Migration[8.0]
  def change
    create_table :chapters, id: :uuid do |t|
      t.string :title
      t.integer :position
      t.references :course, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
