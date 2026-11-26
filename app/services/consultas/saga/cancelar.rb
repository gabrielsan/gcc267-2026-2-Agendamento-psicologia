module Consultas
  module Saga
    # Compensa o desfecho "triagem.reprovada": cancela a reserva pendente,
    # liberando o horário, e emite consulta.reserva_cancelada com o motivo
    # vindo da triagem.
    #
    # Idempotente por omissão, como Confirmar: ignora consultas que já saíram
    # de pendente_triagem.
    class Cancelar
      def self.call(...)
        new(...).call
      end

      def initialize(consulta_id:, motivo: nil)
        @consulta_id = consulta_id
        @motivo = motivo
      end

      def call
        resultado = :ignorado
        Consulta.transaction do
          consulta = Consulta.lock.find(@consulta_id)
          next unless consulta.pendente_triagem?

          consulta.status = :cancelada
          consulta.save!
          RegistrarEvento.call(consulta, "consulta.reserva_cancelada", motivo: @motivo)
          resultado = :cancelado
        end
        resultado
      end
    end
  end
end
