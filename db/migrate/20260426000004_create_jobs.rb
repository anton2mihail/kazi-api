class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs, id: :uuid do |t|
      t.references :employer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :title, null: false
      t.string :trade, null: false
      t.string :location, null: false
      t.text :description
      t.integer :pay_min_cents, null: false
      t.integer :pay_max_cents
      t.string :job_type
      t.string :duration
      t.string :hours_per_week
      t.string :status, null: false, default: "draft"
      t.string :required_certifications, array: true, null: false, default: []
      t.string :preferred_certifications, array: true, null: false, default: []
      t.string :required_skills, array: true, null: false, default: []
      t.string :preferred_skills, array: true, null: false, default: []
      t.string :benefits, array: true, null: false, default: []
      t.datetime :published_at
      t.datetime :expires_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :jobs, [:status, :published_at]
    add_index :jobs, :trade
    add_index :jobs, :location
    add_index :jobs, :expires_at
  end
end
