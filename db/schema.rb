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

ActiveRecord::Schema[8.1].define(version: 2026_04_26_000007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "employer_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "benefits", default: [], null: false, array: true
    t.string "city"
    t.string "company_name"
    t.string "company_size"
    t.string "contact_name"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "industry_type"
    t.string "service_areas", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.boolean "verified", default: false, null: false
    t.string "website"
    t.index ["company_name"], name: "index_employer_profiles_on_company_name"
    t.index ["user_id"], name: "index_employer_profiles_on_user_id", unique: true
    t.index ["verified"], name: "index_employer_profiles_on_verified"
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
    t.string "benefits", default: [], null: false, array: true
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "duration"
    t.uuid "employer_id", null: false
    t.datetime "expires_at"
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
    t.index ["employer_id"], name: "index_jobs_on_employer_id"
    t.index ["expires_at"], name: "index_jobs_on_expires_at"
    t.index ["location"], name: "index_jobs_on_location"
    t.index ["status", "published_at"], name: "index_jobs_on_status_and_published_at"
    t.index ["trade"], name: "index_jobs_on_trade"
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
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "worker_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "availability", default: [], null: false, array: true
    t.text "bio"
    t.string "certifications", default: [], null: false, array: true
    t.string "city"
    t.datetime "created_at", null: false
    t.string "first_name"
    t.integer "hourly_rate_min_cents"
    t.string "last_name"
    t.string "primary_trade"
    t.string "province", default: "ON", null: false
    t.string "secondary_trades", default: [], null: false, array: true
    t.string "skills", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.string "work_areas", default: [], null: false, array: true
    t.integer "years_experience"
    t.index ["city"], name: "index_worker_profiles_on_city"
    t.index ["primary_trade"], name: "index_worker_profiles_on_primary_trade"
    t.index ["user_id"], name: "index_worker_profiles_on_user_id", unique: true
  end

  add_foreign_key "employer_profiles", "users"
  add_foreign_key "job_applications", "jobs"
  add_foreign_key "job_applications", "users", column: "worker_id"
  add_foreign_key "jobs", "users", column: "employer_id"
  add_foreign_key "otp_challenges", "users"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "worker_profiles", "users"
end
