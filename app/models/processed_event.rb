# == Schema Information
#
# Table name: processed_events
#
#  id         :bigint           not null, primary key
#  event_id   :uuid             not null
#  event_type :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_processed_events_on_event_id  (event_id) UNIQUE
#
# Marca event_id já consumidos pela SAGA de agendamento (idempotência do lado
# consumidor). A entrega do broker é "pelo menos uma vez"; sem este registro,
# reentregas duplicariam confirmação/compensação da reserva.
class ProcessedEvent < ApplicationRecord
  validates :event_id, :event_type, presence: true

  # Registra o evento dentro da transação do chamador. Devolve true na
  # primeira vez; false se o event_id já foi processado (conflito no índice
  # único, inclusive sob concorrência entre workers).
  #
  # O insert roda num savepoint próprio: a violação de unicidade aborta só
  # esse savepoint no Postgres, não a transação do chamador (que ainda vai
  # registrar resultado = :evento_duplicado e seguir normalmente).
  def self.registrar(event_id:, event_type:)
    transaction(requires_new: true) { create!(event_id: event_id, event_type: event_type) }
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end
end
