# Outbox da triagem: os eventos triagem.aprovada / triagem.reprovada são gravados
# na mesma transação da avaliação e só depois publicados no broker.
class CriarOutboxEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :outbox_events do |t|
      t.uuid :event_id, null: false
      t.string :event_type, null: false
      t.bigint :consulta_id, null: false
      t.jsonb :payload, null: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :outbox_events, :event_id, unique: true
    add_index :outbox_events, :id, where: "published_at IS NULL", name: "index_outbox_events_pendentes"
  end
end
