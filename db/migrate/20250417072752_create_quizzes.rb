# frozen_string_literal: true

class CreateQuizzes < ActiveRecord::Migration[8.0]
  def change
    create_table :quizzes, id: :uuid do |t|
      t.string :title
      t.boolean :is_exam
      t.integer :time_limit
      t.references :course, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
