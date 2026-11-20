module Triagens
  # Aplica na SAGA o desfecho decidido pelo serviço de agendamento:
  #
  #   consulta.reserva_confirmada → CONFIRMADA
  #   consulta.reserva_cancelada  → COMPENSADA (se a triagem tinha reprovado)
  #                                 ou CANCELADA (cancelamento posterior)
  #                                 e libera o horário reservado na triagem
  #
  # Idempotente pelo mesmo mecanismo de ProcessarReservaCriada. Se a SAGA ainda
  # não existe (evento chegou fora de ordem) levanta RecordNotFound: a mensagem
  # volta para a fila uma vez e depois vai para a DLQ.
  #
  # Retornos: :processado, :evento_duplicado
  class AtualizarSaga
    def self.call(...)
      new(...).call
    end

    def initialize(envelope:)
      @envelope = envelope
    end

    def call
      Saga.transaction do
        next :evento_duplicado unless ProcessedEvent.registrar(@envelope)

        saga = Saga.lock.find_by!(consulta_id: @envelope.consulta_id)
        case @envelope.event_type
        when "consulta.reserva_confirmada" then confirmar(saga)
        when "consulta.reserva_cancelada" then cancelar(saga)
        end
        :processado
      end
    end

    private

    def confirmar(saga)
      avancar(saga, "CONFIRMADA")
    end

    def cancelar(saga)
      destino = saga.estado == "TRIAGEM_REPROVADA" ? "COMPENSADA" : "CANCELADA"
      avancar(saga, destino)
      liberar_horario
    end

    def avancar(saga, destino)
      return if saga.avancar!(destino, event_id: @envelope.event_id)

      Rails.logger.warn("[saga] transição #{saga.estado} → #{destino} ignorada (consulta=#{saga.consulta_id})")
    end

    def liberar_horario
      ReservaTriagem.where(consulta_id: @envelope.consulta_id, ativa: true)
                    .update_all(ativa: false, updated_at: Time.current)
    end
  end
end
