class CriarTabelasDeTriagem < ActiveRecord::Migration[7.1]
  def change
    enable_extension "btree_gist"

    # Idempotência: cada event_id é processado no máximo uma vez.
    create_table :processed_events do |t|
      t.uuid :event_id, null: false
      t.string :event_type, null: false
      t.bigint :consulta_id
      t.datetime :processed_at, null: false
    end
    add_index :processed_events, :event_id, unique: true

    # Resultado da triagem: uma única avaliação por consulta.
    create_table :avaliacoes_triagem do |t|
      t.bigint :consulta_id, null: false
      t.uuid :event_id, null: false
      t.string :status, null: false
      t.string :motivo_codigo
      t.text :motivo_detalhe
      t.datetime :avaliada_em, null: false
      t.timestamps
    end
    add_index :avaliacoes_triagem, :consulta_id, unique: true
    add_check_constraint :avaliacoes_triagem, "status IN ('aprovada', 'reprovada')",
                         name: "avaliacoes_triagem_status_valido"

    # Horários que a triagem já aprovou (usados para checar disponibilidade).
    create_table :reservas_triagem do |t|
      t.bigint :consulta_id, null: false
      t.bigint :estagiario_id, null: false
      t.bigint :professor_id, null: false
      t.string :sala, null: false
      t.datetime :inicio, null: false
      t.datetime :fim, null: false
      t.boolean :ativa, null: false, default: true
      t.timestamps
    end
    add_index :reservas_triagem, :consulta_id, unique: true
    add_check_constraint :reservas_triagem, "fim > inicio", name: "reservas_triagem_fim_depois_do_inicio"
    add_exclusion_constraint :reservas_triagem, "estagiario_id WITH =, tsrange(inicio, fim) WITH &&",
                             using: :gist, where: "ativa", name: "reservas_sem_conflito_estagiario"
    add_exclusion_constraint :reservas_triagem, "sala WITH =, tsrange(inicio, fim) WITH &&",
                             using: :gist, where: "ativa", name: "reservas_sem_conflito_sala"

    # Estado da SAGA de cada reserva, com histórico das transições.
    create_table :sagas do |t|
      t.bigint :consulta_id, null: false
      t.string :estado, null: false
      t.string :motivo_falha
      t.jsonb :historico, null: false, default: []
      t.timestamps
    end
    add_index :sagas, :consulta_id, unique: true
  end
end
