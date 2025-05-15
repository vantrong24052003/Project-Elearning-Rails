# frozen_string_literal: true

class RemoveDeviceInfoAndIpAddressFromQuizAttempts < ActiveRecord::Migration[8.0]
  def change
    remove_column :quiz_attempts, :device_info, :string
    remove_column :quiz_attempts, :ip_address, :string
  end
end
