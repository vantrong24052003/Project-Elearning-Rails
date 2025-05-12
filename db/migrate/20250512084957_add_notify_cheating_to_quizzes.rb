class AddNotifyCheatingToQuizzes < ActiveRecord::Migration[8.0]
  def change
    add_column :quizzes, :notify_cheating, :boolean, default: true
  end
end
