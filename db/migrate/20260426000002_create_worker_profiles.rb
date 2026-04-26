class CreateWorkerProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :worker_profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :first_name
      t.string :last_name
      t.text :bio
      t.string :primary_trade
      t.string :secondary_trades, array: true, null: false, default: []
      t.string :city
      t.string :province, null: false, default: "ON"
      t.string :work_areas, array: true, null: false, default: []
      t.string :availability, array: true, null: false, default: []
      t.string :certifications, array: true, null: false, default: []
      t.string :skills, array: true, null: false, default: []
      t.integer :hourly_rate_min_cents
      t.integer :years_experience

      t.timestamps
    end

    add_index :worker_profiles, :primary_trade
    add_index :worker_profiles, :city
  end
end
