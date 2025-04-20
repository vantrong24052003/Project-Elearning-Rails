# frozen_string_literal: true

class CreateAddInstructorRequestFieldsToDeviseUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :instructor_request_status, :string, default: nil
    add_column :users, :instructor_requested_at, :datetime
    add_column :users, :instructor_reviewed_at, :datetime

    add_index :users, :instructor_request_status
  end
end
