module Mensageria
  # Decide qual caso de uso trata cada tipo de evento.
  class Roteador
    def call(envelope)
      case envelope.event_type
      when "consulta.reserva_criada"
        Triagens::ProcessarReservaCriada.call(envelope: envelope)
      when "consulta.reserva_confirmada", "consulta.reserva_cancelada"
        Triagens::AtualizarSaga.call(envelope: envelope)
      else
        :ignorado
      end
    end
  end
end
