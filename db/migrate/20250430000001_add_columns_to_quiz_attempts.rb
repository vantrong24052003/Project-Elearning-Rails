# frozen_string_literal: true

class AddColumnsToQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_attempts, :answers, :text
    add_column :quiz_attempts, :time_spent, :integer
  end
end
