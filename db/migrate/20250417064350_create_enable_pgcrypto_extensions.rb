class CreateEnablePgcryptoExtensions < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto'
  end
end
