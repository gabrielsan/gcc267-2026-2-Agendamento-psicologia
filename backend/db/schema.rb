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

ActiveRecord::Schema[8.1].define(version: 2026_10_07_000003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"

  create_table "consultas", force: :cascade do |t|
    t.bigint "estagiario_id", null: false
    t.bigint "professor_id", null: false
    t.string "paciente_nome", null: false
    t.string "paciente_telefone"
    t.string "paciente_email"
    t.datetime "inicio", null: false
    t.datetime "fim", null: false
    t.string "sala", null: false
    t.string "status", default: "agendada", null: false
    t.text "observacoes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estagiario_id", "inicio"], name: "index_consultas_on_estagiario_id_and_inicio"
    t.index ["professor_id", "inicio"], name: "index_consultas_on_professor_id_and_inicio"
    t.index ["sala", "inicio"], name: "index_consultas_on_sala_and_inicio"
    t.index ["status"], name: "index_consultas_on_status"
    t.check_constraint "fim > inicio", name: "consultas_fim_depois_do_inicio"
    t.check_constraint "status::text = ANY (ARRAY['agendada'::character varying, 'confirmada'::character varying, 'realizada'::character varying, 'cancelada'::character varying, 'falta'::character varying]::text[])", name: "consultas_status_valido"
    t.exclusion_constraint "estagiario_id WITH =, tsrange(inicio, fim) WITH &&", where: "(status)::text <> 'cancelada'::text", using: :gist, name: "consultas_sem_conflito_estagiario"
    t.exclusion_constraint "sala WITH =, tsrange(inicio, fim) WITH &&", where: "(status)::text <> 'cancelada'::text", using: :gist, name: "consultas_sem_conflito_sala"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti", unique: true
  end

  create_table "usuarios", force: :cascade do |t|
    t.string "type", null: false
    t.string "nome", null: false
    t.string "matricula"
    t.string "telefone"
    t.boolean "ativo", default: true, null: false
    t.bigint "supervisor_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_usuarios_on_email", unique: true
    t.index ["matricula"], name: "index_usuarios_on_matricula", unique: true, where: "(matricula IS NOT NULL)"
    t.index ["supervisor_id"], name: "index_usuarios_on_supervisor_id"
    t.index ["type"], name: "index_usuarios_on_type"
  end

  add_foreign_key "consultas", "usuarios", column: "estagiario_id"
  add_foreign_key "consultas", "usuarios", column: "professor_id"
  add_foreign_key "usuarios", "usuarios", column: "supervisor_id"
end
