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

ActiveRecord::Schema[7.1].define(version: 2026_11_18_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "outbox_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.string "consulta_id", null: false
    t.datetime "occurred_at", null: false
    t.integer "version", default: 1, null: false
    t.string "producer", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "published_at"
    t.datetime "available_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "attempts", default: 0, null: false
    t.string "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["available_at", "id"], name: "outbox_pending", where: "(published_at IS NULL)"
    t.index ["event_id"], name: "index_outbox_events_on_event_id", unique: true
    t.check_constraint "jsonb_typeof(data) = 'object'::text", name: "outbox_data_object"
    t.check_constraint "version = 1 AND attempts >= 0", name: "outbox_metadata_valid"
  end

end
