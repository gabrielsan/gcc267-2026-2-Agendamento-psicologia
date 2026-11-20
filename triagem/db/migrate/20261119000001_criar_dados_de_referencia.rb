# Dados que a triagem precisa para validar sem consultar o banco do serviço de
# agendamento: salas existentes e quem supervisiona cada estagiário.
class CriarDadosDeReferencia < ActiveRecord::Migration[7.1]
  def change
    create_table :salas do |t|
      t.string :nome, null: false
      t.boolean :ativa, null: false, default: true
      t.timestamps
    end
    add_index :salas, :nome, unique: true

    create_table :supervisoes do |t|
      t.bigint :estagiario_id, null: false
      t.bigint :professor_id, null: false
      t.boolean :ativa, null: false, default: true
      t.timestamps
    end
    add_index :supervisoes, :estagiario_id, unique: true
  end
end
