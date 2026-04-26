class CreateWorkflowTables < ActiveRecord::Migration[8.1]
  def change
    create_table :interview_requests, id: :uuid do |t|
      t.references :employer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :worker, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :job, foreign_key: true, type: :uuid
      t.text :message
      t.string :status, null: false, default: "pending"
      t.datetime :responded_at
      t.datetime :cancelled_at

      t.timestamps
    end

    add_index :interview_requests, [ :employer_id, :worker_id, :job_id ], unique: true, where: "cancelled_at IS NULL"
    add_index :interview_requests, [ :worker_id, :status ]
    add_index :interview_requests, [ :employer_id, :created_at ]

    create_table :work_histories, id: :uuid do |t|
      t.references :job, foreign_key: true, type: :uuid
      t.references :worker, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :employer, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.string :job_title, null: false
      t.string :employer_name
      t.string :status, null: false, default: "pending_employer"
      t.datetime :worker_marked_at
      t.datetime :employer_responded_at
      t.boolean :employer_confirmed
      t.datetime :auto_verify_at
      t.text :employer_notes
      t.string :dispute_reason
      t.text :dispute_details
      t.integer :worker_rating
      t.text :worker_review
      t.integer :employer_rating
      t.text :employer_review

      t.timestamps
    end

    add_index :work_histories, [ :worker_id, :status ]
    add_index :work_histories, [ :employer_id, :status ]
    add_index :work_histories, [ :job_id, :worker_id ], unique: true

    create_table :reports, id: :uuid do |t|
      t.references :reporter, foreign_key: { to_table: :users }, type: :uuid
      t.references :job, foreign_key: true, type: :uuid
      t.string :target_type
      t.uuid :target_id
      t.string :reason, null: false
      t.text :details
      t.string :status, null: false, default: "pending"
      t.text :admin_notes
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :reports, [ :status, :created_at ]
    add_index :reports, [ :target_type, :target_id ]

    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message
      t.references :job, foreign_key: true, type: :uuid
      t.uuid :company_id
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at ]
    add_index :notifications, [ :user_id, :created_at ]

    create_table :notification_preferences, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.boolean :new_jobs, null: false, default: true
      t.boolean :application_updates, null: false, default: true
      t.boolean :sms, null: false, default: true
      t.boolean :email, null: false, default: true

      t.timestamps
    end
  end
end
