class CreateOutboxEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :outbox_events do |t|
      t.uuid :event_id, null: false
      t.string :event_type, null: false
      t.string :consulta_id, null: false
      t.datetime :occurred_at, null: false
      t.integer :version, null: false, default: 1
      t.string :producer, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :published_at
      t.datetime :available_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.integer :attempts, null: false, default: 0
      t.string :last_error
      t.timestamps
    end
    add_index :outbox_events, :event_id, unique: true
    add_index :outbox_events, [:available_at, :id], where: "published_at IS NULL", name: "outbox_pending"
    add_check_constraint :outbox_events, "jsonb_typeof(data) = 'object'", name: "outbox_data_object"
    add_check_constraint :outbox_events, "version = 1 AND attempts >= 0", name: "outbox_metadata_valid"
  end
end
