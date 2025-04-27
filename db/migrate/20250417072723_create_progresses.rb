# frozen_string_literal: true

class CreateProgresses < ActiveRecord::Migration[8.0]
  def change
    create_table :progresses, id: :uuid do |t|
      t.string :status
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.references :lesson, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
