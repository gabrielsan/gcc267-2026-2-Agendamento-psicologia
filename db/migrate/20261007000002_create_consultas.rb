class CreateConsultas < ActiveRecord::Migration[7.1]
  def change
    create_table :consultas do |t|
      t.references :estagiario, null: false, index: false, foreign_key: { to_table: :usuarios }
      t.references :professor, null: false, index: false, foreign_key: { to_table: :usuarios }

      t.string :paciente_nome, null: false
      t.string :paciente_telefone
      t.string :paciente_email

      t.datetime :inicio, null: false
      t.datetime :fim, null: false
      t.string :sala, null: false
      t.string :status, null: false, default: "agendada"
      t.text :observacoes

      t.timestamps
    end

    add_index :consultas, [ :estagiario_id, :inicio ]
    add_index :consultas, [ :professor_id, :inicio ]
    add_index :consultas, [ :sala, :inicio ]
    add_index :consultas, :status

    add_check_constraint :consultas, "fim > inicio", name: "consultas_fim_depois_do_inicio"
    add_check_constraint :consultas,
      "status IN ('agendada', 'confirmada', 'realizada', 'cancelada', 'falta')",
      name: "consultas_status_valido"

    # Garantia no banco de que não há choque de horário, mesmo com requisições
    # simultâneas. Consultas canceladas liberam o horário. O intervalo é [inicio, fim),
    # então uma consulta pode começar exatamente quando a anterior termina.
    add_exclusion_constraint :consultas,
      "estagiario_id WITH =, tsrange(inicio, fim) WITH &&",
      using: :gist, where: "status <> 'cancelada'", name: "consultas_sem_conflito_estagiario"
    add_exclusion_constraint :consultas,
      "sala WITH =, tsrange(inicio, fim) WITH &&",
      using: :gist, where: "status <> 'cancelada'", name: "consultas_sem_conflito_sala"
  end
end
