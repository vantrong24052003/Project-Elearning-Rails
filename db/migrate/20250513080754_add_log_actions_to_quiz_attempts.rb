class AddLogActionsToQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_attempts, :log_actions, :jsonb, default: [], null: false
  end
end
