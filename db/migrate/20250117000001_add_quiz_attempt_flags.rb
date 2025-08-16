# frozen_string_literal: true

class AddQuizAttemptFlags < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_attempts, :auto_submitted, :boolean, default: false
    add_column :quiz_attempts, :suspicious, :boolean, default: false
    add_index :quiz_attempts, [:suspicious]
  end
end
