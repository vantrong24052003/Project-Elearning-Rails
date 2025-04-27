class RolifyCreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name
      t.references :resource, polymorphic: true, type: :uuid
      t.timestamps
    end

    create_table :users_roles, id: false do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :role, null: false, foreign_key: true, type: :uuid
    end

    add_index :roles, :name
    add_index :roles, %i[name resource_type resource_id], unique: true
    add_index :users_roles, %i[user_id role_id], unique: true
  end
end
