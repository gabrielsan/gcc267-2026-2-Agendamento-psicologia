module Consultas
  module Saga
    # Ponto de entrada da SAGA no serviço de agendamento: recebe um envelope
    # já decodificado (contrato em docs/contracts/event-v1.schema.json) dos
    # tipos triagem.aprovada/triagem.reprovada, publicados na fila
    # psiline.agendamento, e aplica Confirmar ou Cancelar.
    #
    # O registro de idempotência (ProcessedEvent) e a transição da consulta
    # acontecem na mesma transação local: se qualquer passo falhar, nada é
    # persistido e a mensagem pode ser reentregue com segurança.
    #
    # Devolve :confirmado, :cancelado, :ignorado (consulta não estava mais
    # pendente_triagem) ou :evento_duplicado (event_id já processado).
    class ProcessarResultadoTriagem
      TIPOS_SUPORTADOS = %w[triagem.aprovada triagem.reprovada].freeze

      def self.call(...)
        new(...).call
      end

      def initialize(envelope)
        @envelope = envelope
      end

      def call
        tipo = @envelope.fetch("event_type")
        raise ArgumentError, "tipo de evento inesperado: #{tipo}" unless TIPOS_SUPORTADOS.include?(tipo)

        resultado = nil
        ProcessedEvent.transaction do
          unless ProcessedEvent.registrar(event_id: @envelope.fetch("event_id"), event_type: tipo)
            resultado = :evento_duplicado
            next
          end

          resultado = aplicar(tipo)
        end
        resultado
      end

      private

      def aplicar(tipo)
        consulta_id = Integer(@envelope.fetch("consulta_id"))

        case tipo
        when "triagem.aprovada"
          Confirmar.call(consulta_id: consulta_id)
        when "triagem.reprovada"
          Cancelar.call(consulta_id: consulta_id, motivo: motivo)
        end
      end

      # O contrato propõe data.motivo; aceita a variação já observada em
      # implementações de triagem (motivo_codigo/motivo_detalhe) para não
      # perder a informação por uma diferença de nome de campo. Prefere o
      # código estável; o detalhe (texto livre) é o último recurso.
      def motivo
        dados = @envelope["data"] || {}
        dados["motivo"] || dados["motivo_codigo"] || dados["motivo_detalhe"]
      end
    end
  end
end
