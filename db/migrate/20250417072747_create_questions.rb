# frozen_string_literal: true

class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions, id: :uuid do |t|
      t.text :content
      t.json :options
      t.integer :correct_option
      t.text :explanation
      t.string :difficulty
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
