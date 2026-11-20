# Registro de eventos já tratados. O índice único em event_id é o que garante a
# idempotência, mesmo com dois consumidores processando a mesma mensagem.
class ProcessedEvent < ApplicationRecord
  # Tenta registrar o evento. Devolve true se é a primeira vez, false se o
  # event_id já havia sido processado (INSERT ... ON CONFLICT DO NOTHING).
  def self.registrar(envelope)
    atributos = {
      event_id: envelope.event_id,
      event_type: envelope.event_type,
      consulta_id: envelope.consulta_id,
      processed_at: Time.current
    }
    insert_all([ atributos ], unique_by: :event_id).rows.any?
  end
end
