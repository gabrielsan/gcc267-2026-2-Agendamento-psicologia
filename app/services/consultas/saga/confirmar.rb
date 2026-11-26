module Consultas
  module Saga
    # Aplica o desfecho "triagem.aprovada": a reserva pendente passa a
    # agendada e o evento consulta.reserva_confirmada é emitido.
    #
    # Idempotente por omissão: se a consulta já saiu de pendente_triagem
    # (reentrega do mesmo resultado, ou evento fora de ordem) a chamada não
    # faz nada e devolve :ignorado, em vez de falhar.
    class Confirmar
      def self.call(...)
        new(...).call
      end

      def initialize(consulta_id:)
        @consulta_id = consulta_id
      end

      def call
        resultado = :ignorado
        Consulta.transaction do
          consulta = Consulta.lock.find(@consulta_id)
          next unless consulta.pendente_triagem?

          consulta.status = :agendada
          consulta.save!
          RegistrarEvento.call(consulta, "consulta.reserva_confirmada")
          resultado = :confirmado
        end
        resultado
      end
    end
  end
end
