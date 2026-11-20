module Triagens
  # Trata o evento consulta.reserva_criada: avalia a reserva e registra, numa
  # única transação:
  #
  #   1. o event_id em processed_events   (idempotência)
  #   2. a avaliação (aprovada/reprovada)
  #   3. o horário reservado, se aprovada
  #   4. o novo estado da SAGA
  #   5. o evento triagem.aprovada / triagem.reprovada na outbox
  #
  # Ou tudo acontece, ou nada acontece. Reentregar a mesma mensagem não repete
  # nada: o INSERT em processed_events falha por conflito e o fluxo termina.
  #
  # Retornos: :processado, :evento_duplicado, :consulta_ja_avaliada
  class ProcessarReservaCriada
    def self.call(...)
      new(...).call
    end

    def initialize(envelope:)
      @envelope = envelope
    end

    def call
      AvaliacaoTriagem.transaction do
        next :evento_duplicado unless ProcessedEvent.registrar(@envelope)
        # Outro event_id para a mesma consulta (reenvio com id novo): não avalia de novo.
        next :consulta_ja_avaliada if AvaliacaoTriagem.exists?(consulta_id: @envelope.consulta_id)

        reserva, veredito = avaliar
        registrar_resultado(reserva, veredito)
        :processado
      end
    rescue ActiveRecord::RecordNotUnique
      # Corrida entre dois consumidores com event_ids diferentes para a mesma consulta.
      :consulta_ja_avaliada
    end

    private

    def avaliar
      reserva = Reserva.from_envelope(@envelope)
      veredito = Avaliar.call(reserva)
      veredito = reservar_horario(reserva) if veredito.aprovada?
      [ reserva, veredito ]
    rescue PayloadInvalido => e
      [ nil, Veredito.reprovado("PAYLOAD_INVALIDO", e.message) ]
    end

    # O banco é a última barreira: duas aprovações simultâneas para o mesmo
    # horário esbarram nas exclusion constraints e uma delas vira reprovação.
    def reservar_horario(reserva)
      ReservaTriagem.transaction(requires_new: true) do
        ReservaTriagem.create!(
          consulta_id: reserva.consulta_id, estagiario_id: reserva.estagiario_id,
          professor_id: reserva.professor_id, sala: reserva.sala,
          inicio: reserva.inicio, fim: reserva.fim, ativa: true
        )
      end
      Veredito.aprovado
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.cause.is_a?(PG::ExclusionViolation)

      Veredito.reprovado("HORARIO_CONFLITANTE", "O horário foi ocupado por outra reserva aprovada ao mesmo tempo.")
    end

    def registrar_resultado(reserva, veredito)
      consulta_id = @envelope.consulta_id

      AvaliacaoTriagem.create!(
        consulta_id: consulta_id, event_id: @envelope.event_id, status: veredito.status,
        motivo_codigo: veredito.codigo, motivo_detalhe: veredito.detalhe, avaliada_em: Time.current
      )

      saga = Saga.iniciar!(consulta_id: consulta_id, event_id: @envelope.event_id)
      saga.avancar!(veredito.aprovada? ? "TRIAGEM_APROVADA" : "TRIAGEM_REPROVADA",
                    event_id: @envelope.event_id, motivo: veredito.codigo)

      OutboxEvent.registrar!(
        event_type: veredito.aprovada? ? "triagem.aprovada" : "triagem.reprovada",
        consulta_id: consulta_id,
        causation_id: @envelope.event_id,
        data: dados_da_resposta(reserva, veredito)
      )
    end

    def dados_da_resposta(reserva, veredito)
      base = reserva ? reserva.to_event_data : @envelope.data.slice("estagiario_id", "professor_id", "sala", "inicio", "fim")
      return base if veredito.aprovada?

      base.merge("motivo_codigo" => veredito.codigo, "motivo_detalhe" => veredito.detalhe)
    end
  end
end
