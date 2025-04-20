# frozen_string_literal: true

class AddConfirmableToDeviseUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users do |t|
      # Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      t.index :confirmation_token, unique: true
    end

    reversible do |dir|
      dir.up do
        User.update_all(confirmed_at: Time.now)
      end
    end
  end
end
