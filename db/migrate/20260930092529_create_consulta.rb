class CreateConsulta < ActiveRecord::Migration[7.1]
  def change
    create_table :consultas do |t|
      t.references :estagiario, null: false, foreign_key: true
      t.references :professor, null: false, foreign_key: { to_table: :professors }
      t.string :patient_name, null: false
      t.string :patient_email
      t.string :patient_phone
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.integer :modality, null: false, default: 0
      t.string :room
      t.text :notes
      t.text :supervision_notes

      t.timestamps
    end

    add_index :consultas, :starts_at
    add_index :consultas, :status
    add_index :consultas, [:estagiario_id, :starts_at]
    add_index :consultas, [:professor_id, :starts_at]
  end
end
