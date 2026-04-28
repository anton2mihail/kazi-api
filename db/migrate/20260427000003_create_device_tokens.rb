class CreateDeviceTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :device_tokens, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true, index: true
      t.string :expo_push_token, null: false
      t.string :platform, null: false
      t.string :app_version
      t.string :locale
      t.boolean :active, null: false, default: true
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :device_tokens, :expo_push_token, unique: true
    add_index :device_tokens, [ :user_id, :active ]
  end
end
