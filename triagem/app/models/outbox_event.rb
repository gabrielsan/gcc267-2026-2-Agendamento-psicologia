class OutboxEvent < ApplicationRecord
  scope :pendentes, -> { where(published_at: nil) }

  # Grava o evento na outbox. Deve ser chamado dentro da mesma transação que
  # altera o estado do serviço.
  def self.registrar!(event_type:, consulta_id:, data:, causation_id: nil)
    event_id = SecureRandom.uuid
    create!(
      event_id: event_id,
      event_type: event_type,
      consulta_id: consulta_id,
      payload: Mensageria::Envelope.montar(
        event_id: event_id, event_type: event_type, consulta_id: consulta_id,
        data: data, causation_id: causation_id
      )
    )
  end
end
