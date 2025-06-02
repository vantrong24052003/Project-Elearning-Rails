# frozen_string_literal: true

class AddTimeFieldsToQuizzes < ActiveRecord::Migration[8.0]
  def change
    add_column :quizzes, :start_time, :datetime
    add_column :quizzes, :end_time, :datetime
  end
end
