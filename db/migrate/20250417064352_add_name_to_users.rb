# frozen_string_literal: true

class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :address, :string
    add_column :users, :name, :string
    add_column :users, :avatar, :string
    add_column :users, :bio, :text
    add_column :users, :date_of_birth, :date
  end
end
