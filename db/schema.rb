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

ActiveRecord::Schema[8.1].define(version: 2025_09_25_221509) do
  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes", default: 30
    t.text "notes"
    t.integer "patient_id", null: false
    t.integer "practice_id", null: false
    t.integer "provider_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "status", default: "scheduled"
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
    t.index ["practice_id"], name: "index_appointments_on_practice_id"
    t.index ["provider_id"], name: "index_appointments_on_provider_id"
  end

  create_table "medical_records", force: :cascade do |t|
    t.text "allergies"
    t.integer "appointment_id", null: false
    t.integer "blood_pressure_diastolic"
    t.integer "blood_pressure_systolic"
    t.datetime "created_at", null: false
    t.text "diagnosis"
    t.integer "heart_rate"
    t.decimal "height", precision: 5, scale: 2
    t.text "medications"
    t.text "notes"
    t.integer "patient_id", null: false
    t.datetime "recorded_at", null: false
    t.decimal "temperature", precision: 4, scale: 2
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 5, scale: 2
    t.index ["appointment_id"], name: "index_medical_records_on_appointment_id"
    t.index ["patient_id"], name: "index_medical_records_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "address"
    t.string "blood_type"
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "email"
    t.text "emergency_contact_name"
    t.text "emergency_contact_phone"
    t.string "first_name", null: false
    t.string "gender"
    t.string "insurance_policy_number"
    t.string "insurance_provider"
    t.string "last_name", null: false
    t.string "phone", null: false
    t.integer "practice_id", null: false
    t.datetime "updated_at", null: false
    t.index ["practice_id"], name: "index_patients_on_practice_id"
  end

  create_table "practices", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "license_number"
    t.string "name"
    t.string "phone"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_practices_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "tenant"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "staffs", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "license_number"
    t.integer "practice_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["practice_id"], name: "index_staffs_on_practice_id"
    t.index ["user_id"], name: "index_staffs_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "appointments", "patients", on_delete: :cascade
  add_foreign_key "medical_records", "appointments"
  add_foreign_key "medical_records", "patients"
end
