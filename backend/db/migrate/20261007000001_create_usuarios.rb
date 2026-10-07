class CreateUsuarios < ActiveRecord::Migration[8.1]
  def change
    # Necessária para as exclusion constraints de conflito de horário (consultas).
    enable_extension "btree_gist"

    # Tabela única para Admin, Professor e Estagiario (STI pela coluna "type").
    create_table :usuarios do |t|
      t.string :type, null: false
      t.string :nome, null: false
      t.string :matricula
      t.string :telefone
      t.boolean :ativo, null: false, default: true

      # Somente Estagiario: professor que o supervisiona.
      t.references :supervisor, foreign_key: { to_table: :usuarios }

      ## Devise (database_authenticatable)
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      t.timestamps
    end

    add_index :usuarios, :email, unique: true
    add_index :usuarios, :matricula, unique: true, where: "matricula IS NOT NULL"
    add_index :usuarios, :type
  end
end
