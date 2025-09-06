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

ActiveRecord::Schema[8.1].define(version: 2025_09_06_203450) do
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
    t.datetime "updated_at", null: false
  end

  create_table "practices", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "address"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "license_number"
    t.string "name"
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
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

  add_foreign_key "sessions", "users"
  add_foreign_key "staffs", "practices"
  add_foreign_key "staffs", "users"
end
