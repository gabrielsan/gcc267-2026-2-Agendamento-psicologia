class AddDeviseToProfessors < ActiveRecord::Migration[7.1]
  def change
    change_table :professors do |t|
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
    end

    add_index :professors, :reset_password_token, unique: true
  end
end
