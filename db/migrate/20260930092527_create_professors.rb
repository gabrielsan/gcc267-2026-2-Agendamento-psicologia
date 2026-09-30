class CreateProfessors < ActiveRecord::Migration[7.1]
  def change
    create_table :professors do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :crp, null: false
      t.string :specialty
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :professors, :email, unique: true
    add_index :professors, :crp, unique: true
    add_index :professors, :active
  end
end
