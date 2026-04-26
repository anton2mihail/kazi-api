class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :phone, null: false
      t.string :email
      t.string :role, null: false
      t.boolean :phone_verified, null: false, default: false
      t.boolean :email_verified, null: false, default: false
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :email, unique: true, where: "email IS NOT NULL"
    add_index :users, :role
  end
end
