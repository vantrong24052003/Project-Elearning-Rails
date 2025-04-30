# frozen_string_literal: true

class CreateEnrollments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrollments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :course, null: false, foreign_key: true, type: :uuid
      t.string :status, default: 'pending'
      t.string :payment_code
      t.string :payment_method
      t.decimal :amount, precision: 10, scale: 2
      t.datetime :paid_at
      t.datetime :enrolled_at
      t.datetime :completed_at
      t.string :note

      t.timestamps
    end

    add_index :enrollments, %i[user_id course_id], unique: true
    add_index :enrollments, :payment_code, unique: true
  end
end
