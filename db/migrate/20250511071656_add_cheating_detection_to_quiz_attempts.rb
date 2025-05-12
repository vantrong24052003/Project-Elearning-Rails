class AddCheatingDetectionToQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    add_column :quiz_attempts, :start_time, :datetime
    add_column :quiz_attempts, :completed_at, :datetime
    add_column :quiz_attempts, :device_info, :string
    add_column :quiz_attempts, :ip_address, :string
    add_column :quiz_attempts, :tab_switch_count, :integer, default: 0
    add_column :quiz_attempts, :copy_paste_count, :integer, default: 0
    add_column :quiz_attempts, :screenshot_count, :integer, default: 0
    add_column :quiz_attempts, :right_click_count, :integer, default: 0
    add_column :quiz_attempts, :devtools_open_count, :integer, default: 0
    add_column :quiz_attempts, :other_unusual_actions, :integer, default: 0
    add_column :quiz_attempts, :device_count, :integer, default: 1
    add_column :quiz_attempts, :is_notified, :boolean, default: false
    add_column :quiz_attempts, :notified_at, :datetime
  end
end
