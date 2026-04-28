class CreatePushTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :push_tickets, id: :uuid do |t|
      t.string :ticket_id, null: false
      t.references :device_token, null: false, foreign_key: true, type: :uuid
      t.datetime :sent_at, null: false

      t.timestamps
    end

    add_index :push_tickets, :ticket_id, unique: true
    add_index :push_tickets, [ :device_token_id, :sent_at ]
  end
end
