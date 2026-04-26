class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications, id: :uuid do |t|
      t.references :job, null: false, foreign_key: true, type: :uuid
      t.references :worker, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :status, null: false, default: "pending"
      t.text :cover_note
      t.datetime :withdrawn_at

      t.timestamps
    end

    add_index :job_applications, [ :job_id, :worker_id ], unique: true
    add_index :job_applications, [ :worker_id, :status ]
    add_index :job_applications, [ :job_id, :status ]
  end
end
