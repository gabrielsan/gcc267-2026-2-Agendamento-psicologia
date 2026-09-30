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

ActiveRecord::Schema[7.1].define(version: 2026_09_30_093000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "consultas", force: :cascade do |t|
    t.bigint "estagiario_id", null: false
    t.bigint "professor_id", null: false
    t.string "patient_name", null: false
    t.string "patient_email"
    t.string "patient_phone"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.integer "modality", default: 0, null: false
    t.string "room"
    t.text "notes"
    t.text "supervision_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estagiario_id", "starts_at"], name: "index_consultas_on_estagiario_id_and_starts_at"
    t.index ["estagiario_id"], name: "index_consultas_on_estagiario_id"
    t.index ["professor_id", "starts_at"], name: "index_consultas_on_professor_id_and_starts_at"
    t.index ["professor_id"], name: "index_consultas_on_professor_id"
    t.index ["starts_at"], name: "index_consultas_on_starts_at"
    t.index ["status"], name: "index_consultas_on_status"
  end

  create_table "estagiarios", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.string "registration", null: false
    t.string "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_estagiarios_on_email", unique: true
    t.index ["registration"], name: "index_estagiarios_on_registration", unique: true
    t.index ["reset_password_token"], name: "index_estagiarios_on_reset_password_token", unique: true
  end

  create_table "professors", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "crp", null: false
    t.string "specialty"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["active"], name: "index_professors_on_active"
    t.index ["crp"], name: "index_professors_on_crp", unique: true
    t.index ["email"], name: "index_professors_on_email", unique: true
    t.index ["reset_password_token"], name: "index_professors_on_reset_password_token", unique: true
  end

  add_foreign_key "consultas", "estagiarios"
  add_foreign_key "consultas", "professors"
end
