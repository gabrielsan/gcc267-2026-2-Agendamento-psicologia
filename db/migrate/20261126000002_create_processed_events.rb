class CreateProcessedEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :processed_events do |t|
      t.uuid :event_id, null: false
      t.string :event_type, null: false
      t.timestamps
    end
    add_index :processed_events, :event_id, unique: true
  end
end
