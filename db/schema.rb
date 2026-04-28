# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_27_000004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.uuid "actor_id"
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.uuid "subject_id"
    t.string "subject_type"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["subject_type", "subject_id"], name: "index_audit_logs_on_subject_type_and_subject_id"
  end

  create_table "device_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "app_version"
    t.datetime "created_at", null: false
    t.string "expo_push_token", null: false
    t.datetime "last_seen_at"
    t.string "locale"
    t.string "platform", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["expo_push_token"], name: "index_device_tokens_on_expo_push_token", unique: true
    t.index ["user_id", "active"], name: "index_device_tokens_on_user_id_and_active"
    t.index ["user_id"], name: "index_device_tokens_on_user_id"
  end

  create_table "employer_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "benefits", default: [], null: false, array: true
    t.string "city"
    t.string "company_name"
    t.string "company_size"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "industry_type"
    t.string "job_title"
    t.string "office_locations", default: [], null: false, array: true
    t.string "phone"
    t.datetime "rejected_at"
    t.string "service_areas", default: [], null: false, array: true
    t.jsonb "social_media", default: {}, null: false
    t.datetime "suspended_at"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.text "verification_notes"
    t.string "verification_status", default: "pending", null: false
    t.integer "verification_step", default: 3, null: false
    t.datetime "verification_submitted_at"
    t.boolean "verified", default: false, null: false
    t.datetime "verified_at"
    t.string "website"
    t.index ["company_name"], name: "index_employer_profiles_on_company_name"
    t.index ["office_locations"], name: "index_employer_profiles_on_office_locations", using: :gin
    t.index ["user_id"], name: "index_employer_profiles_on_user_id", unique: true
    t.index ["verification_status"], name: "index_employer_profiles_on_verification_status"
    t.index ["verified"], name: "index_employer_profiles_on_verified"
  end

  create_table "interview_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.uuid "employer_id", null: false
    t.uuid "job_id"
    t.text "message"
    t.datetime "responded_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.uuid "worker_id", null: false
    t.index ["employer_id", "created_at"], name: "index_interview_requests_on_employer_id_and_created_at"
    t.index ["employer_id", "worker_id", "job_id"], name: "idx_on_employer_id_worker_id_job_id_cd12267129", unique: true, where: "(cancelled_at IS NULL)"
    t.index ["employer_id"], name: "index_interview_requests_on_employer_id"
    t.index ["job_id"], name: "index_interview_requests_on_job_id"
    t.index ["worker_id", "status"], name: "index_interview_requests_on_worker_id_and_status"
    t.index ["worker_id"], name: "index_interview_requests_on_worker_id"
  end

  create_table "invite_codes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "code", null: false
    t.string "company_name", null: false
    t.string "contact_email"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.boolean "pre_approved", default: true, null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.uuid "used_by_id"
    t.index ["code"], name: "index_invite_codes_on_code", unique: true
    t.index ["used_at"], name: "index_invite_codes_on_used_at"
    t.index ["used_by_id"], name: "index_invite_codes_on_used_by_id"
  end

  create_table "job_applications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "cover_note"
    t.datetime "created_at", null: false
    t.uuid "job_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "withdrawn_at"
    t.uuid "worker_id", null: false
    t.index ["job_id", "status"], name: "index_job_applications_on_job_id_and_status"
    t.index ["job_id", "worker_id"], name: "index_job_applications_on_job_id_and_worker_id", unique: true
    t.index ["job_id"], name: "index_job_applications_on_job_id"
    t.index ["worker_id", "status"], name: "index_job_applications_on_worker_id_and_status"
    t.index ["worker_id"], name: "index_job_applications_on_worker_id"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "archived_at"
    t.string "benefits", default: [], null: false, array: true
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "duration"
    t.uuid "employer_id", null: false
    t.datetime "expires_at"
    t.datetime "fraud_flagged_at"
    t.string "hours_per_week"
    t.string "job_type"
    t.string "location", null: false
    t.integer "pay_max_cents"
    t.integer "pay_min_cents", null: false
    t.string "preferred_certifications", default: [], null: false, array: true
    t.string "preferred_skills", default: [], null: false, array: true
    t.datetime "published_at"
    t.string "required_certifications", default: [], null: false, array: true
    t.string "required_skills", default: [], null: false, array: true
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.string "trade", null: false
    t.datetime "updated_at", null: false
    t.boolean "urgent", default: false, null: false
    t.index ["archived_at"], name: "index_jobs_on_archived_at"
    t.index ["employer_id"], name: "index_jobs_on_employer_id"
    t.index ["expires_at"], name: "index_jobs_on_expires_at"
    t.index ["location"], name: "index_jobs_on_location"
    t.index ["status", "published_at"], name: "index_jobs_on_status_and_published_at"
    t.index ["trade"], name: "index_jobs_on_trade"
  end

  create_table "notification_preferences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "application_updates", default: true, null: false
    t.datetime "created_at", null: false
    t.boolean "email", default: true, null: false
    t.boolean "new_jobs", default: true, null: false
    t.boolean "sms", default: true, null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id"
    t.datetime "created_at", null: false
    t.uuid "job_id"
    t.text "message"
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["job_id"], name: "index_notifications_on_job_id"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "otp_challenges", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "attempts_count", default: 0, null: false
    t.string "code_digest", null: false
    t.datetime "consumed_at"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "phone", null: false
    t.string "purpose", null: false
    t.string "requested_role"
    t.datetime "updated_at", null: false
    t.uuid "user_id"
    t.index ["consumed_at"], name: "index_otp_challenges_on_consumed_at"
    t.index ["phone", "purpose", "expires_at"], name: "index_otp_challenges_on_phone_and_purpose_and_expires_at"
    t.index ["user_id"], name: "index_otp_challenges_on_user_id"
  end

  create_table "push_tickets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.uuid "device_token_id", null: false
    t.datetime "sent_at", null: false
    t.string "ticket_id", null: false
    t.datetime "updated_at", null: false
    t.index ["device_token_id", "sent_at"], name: "index_push_tickets_on_device_token_id_and_sent_at"
    t.index ["device_token_id"], name: "index_push_tickets_on_device_token_id"
    t.index ["ticket_id"], name: "index_push_tickets_on_ticket_id", unique: true
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "admin_notes"
    t.datetime "created_at", null: false
    t.text "details"
    t.uuid "job_id"
    t.string "reason", null: false
    t.uuid "reporter_id"
    t.datetime "reviewed_at"
    t.uuid "reviewed_by_id"
    t.string "status", default: "pending", null: false
    t.uuid "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_reports_on_job_id"
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["reviewed_by_id"], name: "index_reports_on_reviewed_by_id"
    t.index ["status", "created_at"], name: "index_reports_on_status_and_created_at"
    t.index ["target_type", "target_id"], name: "index_reports_on_target_type_and_target_id"
  end

  create_table "user_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.datetime "last_used_at"
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["expires_at"], name: "index_user_sessions_on_expires_at"
    t.index ["token_digest"], name: "index_user_sessions_on_token_digest", unique: true
    t.index ["user_id", "revoked_at"], name: "index_user_sessions_on_user_id_and_revoked_at"
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.boolean "email_verified", default: false, null: false
    t.datetime "last_seen_at"
    t.string "phone", null: false
    t.boolean "phone_verified", default: false, null: false
    t.string "role", null: false
    t.datetime "suspended_at"
    t.uuid "suspended_by_id"
    t.text "suspension_reason"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["suspended_at"], name: "index_users_on_suspended_at"
    t.index ["suspended_by_id"], name: "index_users_on_suspended_by_id"
  end

  create_table "work_histories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "auto_verify_at"
    t.datetime "created_at", null: false
    t.text "dispute_details"
    t.string "dispute_reason"
    t.boolean "employer_confirmed"
    t.uuid "employer_id", null: false
    t.string "employer_name"
    t.text "employer_notes"
    t.integer "employer_rating"
    t.datetime "employer_responded_at"
    t.text "employer_review"
    t.uuid "job_id"
    t.string "job_title", null: false
    t.string "status", default: "pending_employer", null: false
    t.datetime "updated_at", null: false
    t.uuid "worker_id", null: false
    t.datetime "worker_marked_at"
    t.integer "worker_rating"
    t.text "worker_review"
    t.index ["employer_id", "status"], name: "index_work_histories_on_employer_id_and_status"
    t.index ["employer_id"], name: "index_work_histories_on_employer_id"
    t.index ["job_id", "worker_id"], name: "index_work_histories_on_job_id_and_worker_id", unique: true
    t.index ["job_id"], name: "index_work_histories_on_job_id"
    t.index ["worker_id", "status"], name: "index_work_histories_on_worker_id_and_status"
    t.index ["worker_id"], name: "index_work_histories_on_worker_id"
  end

  create_table "worker_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "availability", default: [], null: false, array: true
    t.text "bio"
    t.string "certifications", default: [], null: false, array: true
    t.string "city"
    t.datetime "created_at", null: false
    t.string "custom_certifications", default: [], null: false, array: true
    t.string "driving_licenses", default: [], null: false, array: true
    t.string "first_name"
    t.uuid "followed_company_ids", default: [], null: false, array: true
    t.string "gender"
    t.boolean "has_own_tools", default: false, null: false
    t.boolean "has_transportation", default: true, null: false
    t.integer "hourly_rate_min_cents"
    t.string "last_name"
    t.string "primary_trade"
    t.datetime "profile_updated_at"
    t.string "province", default: "ON", null: false
    t.string "secondary_trades", default: [], null: false, array: true
    t.string "skills", default: [], null: false, array: true
    t.datetime "skills_added_at"
    t.string "start_month"
    t.string "start_year"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "verified_certifications", default: [], null: false, array: true
    t.string "work_areas", default: [], null: false, array: true
    t.string "work_radius", default: "30", null: false
    t.integer "years_experience"
    t.index ["city"], name: "index_worker_profiles_on_city"
    t.index ["driving_licenses"], name: "index_worker_profiles_on_driving_licenses", using: :gin
    t.index ["followed_company_ids"], name: "index_worker_profiles_on_followed_company_ids", using: :gin
    t.index ["primary_trade"], name: "index_worker_profiles_on_primary_trade"
    t.index ["user_id"], name: "index_worker_profiles_on_user_id", unique: true
  end

  add_foreign_key "audit_logs", "users", column: "actor_id"
  add_foreign_key "device_tokens", "users"
  add_foreign_key "employer_profiles", "users"
  add_foreign_key "interview_requests", "jobs"
  add_foreign_key "interview_requests", "users", column: "employer_id"
  add_foreign_key "interview_requests", "users", column: "worker_id"
  add_foreign_key "invite_codes", "users", column: "used_by_id"
  add_foreign_key "job_applications", "jobs"
  add_foreign_key "job_applications", "users", column: "worker_id"
  add_foreign_key "jobs", "users", column: "employer_id"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "jobs"
  add_foreign_key "notifications", "users"
  add_foreign_key "otp_challenges", "users"
  add_foreign_key "push_tickets", "device_tokens"
  add_foreign_key "reports", "jobs"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "reports", "users", column: "reviewed_by_id"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "users", "users", column: "suspended_by_id"
  add_foreign_key "work_histories", "jobs"
  add_foreign_key "work_histories", "users", column: "employer_id"
  add_foreign_key "work_histories", "users", column: "worker_id"
  add_foreign_key "worker_profiles", "users"
end
