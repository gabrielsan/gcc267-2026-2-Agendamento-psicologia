module Messaging
  class OutboxEvent < ActiveRecord::Base
    self.table_name = "outbox_events"

    TYPES = %w[consulta.reserva_criada triagem.aprovada triagem.reprovada consulta.reserva_confirmada consulta.reserva_cancelada].freeze

    validates :event_id, :consulta_id, :occurred_at, :producer, presence: true
    validates :event_type, inclusion: { in: TYPES }
    validates :version, numericality: { only_integer: true, equal_to: 1 }
    validate :data_is_object

    scope :pending, -> { where(published_at: nil).where("available_at <= ?", Time.current) }

    def envelope
      {
        event_id: event_id, event_type: event_type, consulta_id: consulta_id,
        occurred_at: occurred_at.iso8601(6), version: version, producer: producer, data: data
      }
    end

    private

    def data_is_object
      errors.add(:data, "must be a JSON object") unless data.is_a?(Hash)
    end
  end
end
