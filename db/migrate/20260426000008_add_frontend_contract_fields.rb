class AddFrontendContractFields < ActiveRecord::Migration[8.1]
  def change
    change_table :worker_profiles, bulk: true do |t|
      t.string :custom_certifications, array: true, null: false, default: []
      t.string :verified_certifications, array: true, null: false, default: []
      t.datetime :skills_added_at
      t.string :work_radius, null: false, default: "30"
      t.boolean :has_transportation, null: false, default: true
      t.boolean :has_own_tools, null: false, default: false
      t.string :driving_licenses, array: true, null: false, default: []
      t.string :gender
      t.uuid :followed_company_ids, array: true, null: false, default: []
      t.datetime :profile_updated_at
      t.string :start_month
      t.string :start_year
    end

    add_index :worker_profiles, :followed_company_ids, using: :gin
    add_index :worker_profiles, :driving_licenses, using: :gin

    change_table :employer_profiles, bulk: true do |t|
      t.string :job_title
      t.string :email
      t.string :phone
      t.string :office_locations, array: true, null: false, default: []
      t.jsonb :social_media, null: false, default: {}
      t.string :verification_status, null: false, default: "pending"
      t.integer :verification_step, null: false, default: 3
      t.datetime :verification_submitted_at
      t.datetime :verified_at
      t.datetime :rejected_at
      t.datetime :suspended_at
      t.text :verification_notes
    end

    add_index :employer_profiles, :verification_status
    add_index :employer_profiles, :office_locations, using: :gin

    change_table :jobs, bulk: true do |t|
      t.boolean :urgent, null: false, default: false
      t.datetime :archived_at
      t.datetime :fraud_flagged_at
    end

    add_index :jobs, :archived_at

    create_table :invite_codes, id: :uuid do |t|
      t.string :code, null: false
      t.string :company_name, null: false
      t.string :contact_email
      t.boolean :pre_approved, null: false, default: true
      t.datetime :expires_at
      t.datetime :used_at
      t.references :used_by, foreign_key: { to_table: :users }, type: :uuid

      t.timestamps
    end

    add_index :invite_codes, :code, unique: true
    add_index :invite_codes, :used_at

    create_table :audit_logs, id: :uuid do |t|
      t.references :actor, foreign_key: { to_table: :users }, type: :uuid
      t.string :action, null: false
      t.string :subject_type
      t.uuid :subject_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :audit_logs, [ :subject_type, :subject_id ]
    add_index :audit_logs, :action
  end
end
