module Messaging
  module Outbox
    # Call inside the SAME transaction as the domain write, in the service's own DB.
    def self.record!(event_type:, consulta_id:, data:, event_id: SecureRandom.uuid)
      unless OutboxEvent.connection.transaction_open?
        raise ArgumentError, "Outbox.record! requires a domain transaction"
      end

      OutboxEvent.create!(
        event_id: event_id, event_type: event_type, consulta_id: consulta_id.to_s,
        occurred_at: Time.current, version: 1,
        producer: ENV.fetch("SERVICE_NAME", "agendamento"), data: data
      )
    end
  end
end
