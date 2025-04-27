# frozen_string_literal: true

class CreateEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrollments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.string :status
      t.datetime :enrolled_at
      t.datetime :completed_at
      t.decimal :price_paid

      t.timestamps
    end

    add_index :enrollments, %i[user_id course_id], unique: true
  end
end
