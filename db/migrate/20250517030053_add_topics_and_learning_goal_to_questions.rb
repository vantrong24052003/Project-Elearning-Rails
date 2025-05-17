# frozen_string_literal: true

class AddTopicsAndLearningGoalToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :topic, :string, null: false
    add_column :questions, :learning_goal, :string, null: false
  end
end
