class AddPendenteTriagemStatus < ActiveRecord::Migration[7.1]
  def up
    remove_check_constraint :consultas, name: "consultas_status_valido"
    add_check_constraint :consultas,
      "status::text = ANY (ARRAY['pendente_triagem', 'agendada', 'confirmada', 'cancelada', 'falta', 'realizada'])",
      name: "consultas_status_valido"
    change_column_default :consultas, :status, from: "agendada", to: "pendente_triagem"
  end

  def down
    change_column_default :consultas, :status, from: "pendente_triagem", to: "agendada"
    remove_check_constraint :consultas, name: "consultas_status_valido"
    add_check_constraint :consultas,
      "status::text = ANY (ARRAY['agendada', 'confirmada', 'realizada', 'cancelada', 'falta'])",
      name: "consultas_status_valido"
  end
end
