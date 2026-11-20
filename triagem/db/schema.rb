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

ActiveRecord::Schema[7.1].define(version: 2026_11_19_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "plpgsql"

  create_table "avaliacoes_triagem", force: :cascade do |t|
    t.bigint "consulta_id", null: false
    t.uuid "event_id", null: false
    t.string "status", null: false
    t.string "motivo_codigo"
    t.text "motivo_detalhe"
    t.datetime "avaliada_em", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consulta_id"], name: "index_avaliacoes_triagem_on_consulta_id", unique: true
    t.check_constraint "status::text = ANY (ARRAY['aprovada'::character varying, 'reprovada'::character varying]::text[])", name: "avaliacoes_triagem_status_valido"
  end

  create_table "outbox_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.bigint "consulta_id", null: false
    t.jsonb "payload", null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_outbox_events_on_event_id", unique: true
    t.index ["id"], name: "index_outbox_events_pendentes", where: "(published_at IS NULL)"
  end

  create_table "processed_events", force: :cascade do |t|
    t.uuid "event_id", null: false
    t.string "event_type", null: false
    t.bigint "consulta_id"
    t.datetime "processed_at", null: false
    t.index ["event_id"], name: "index_processed_events_on_event_id", unique: true
  end

  create_table "reservas_triagem", force: :cascade do |t|
    t.bigint "consulta_id", null: false
    t.bigint "estagiario_id", null: false
    t.bigint "professor_id", null: false
    t.string "sala", null: false
    t.datetime "inicio", null: false
    t.datetime "fim", null: false
    t.boolean "ativa", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consulta_id"], name: "index_reservas_triagem_on_consulta_id", unique: true
    t.check_constraint "fim > inicio", name: "reservas_triagem_fim_depois_do_inicio"
    t.exclusion_constraint "estagiario_id WITH =, tsrange(inicio, fim) WITH &&", where: "tiv", using: :gist, name: "reservas_sem_conflito_estagiario"
    t.exclusion_constraint "sala WITH =, tsrange(inicio, fim) WITH &&", where: "tiv", using: :gist, name: "reservas_sem_conflito_sala"
  end

  create_table "sagas", force: :cascade do |t|
    t.bigint "consulta_id", null: false
    t.string "estado", null: false
    t.string "motivo_falha"
    t.jsonb "historico", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["consulta_id"], name: "index_sagas_on_consulta_id", unique: true
  end

  create_table "salas", force: :cascade do |t|
    t.string "nome", null: false
    t.boolean "ativa", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_salas_on_nome", unique: true
  end

  create_table "supervisoes", force: :cascade do |t|
    t.bigint "estagiario_id", null: false
    t.bigint "professor_id", null: false
    t.boolean "ativa", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estagiario_id"], name: "index_supervisoes_on_estagiario_id", unique: true
  end

end
