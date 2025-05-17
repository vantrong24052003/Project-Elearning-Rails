class AddStatusAndValidUntilToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :status, :string, default: 'active', null: false
    add_column :questions, :valid_until, :datetime
    add_index :questions, :status
  end
end
