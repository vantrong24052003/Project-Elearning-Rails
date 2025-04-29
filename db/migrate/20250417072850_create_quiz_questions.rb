# frozen_string_literal: true

class CreateQuizQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :quiz_questions, id: :uuid do |t|
      t.references :quiz, null: false, foreign_key: true, type: :uuid
      t.references :question, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
