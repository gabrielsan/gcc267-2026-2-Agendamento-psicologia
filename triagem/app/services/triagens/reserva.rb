module Triagens
  # Dados da reserva extraídos do evento consulta.reserva_criada.
  class Reserva < Struct.new(:consulta_id, :estagiario_id, :professor_id, :sala, :inicio, :fim, :paciente_nome,
                             keyword_init: true)
    CAMPOS_OBRIGATORIOS = %w[estagiario_id professor_id sala inicio fim paciente_nome].freeze

    def self.from_envelope(envelope)
      dados = envelope.data
      ausentes = CAMPOS_OBRIGATORIOS.select { |campo| dados[campo].blank? }
      raise PayloadInvalido, "campos ausentes em data: #{ausentes.join(', ')}" if ausentes.any?

      inicio = Time.iso8601(dados["inicio"].to_s)
      fim = Time.iso8601(dados["fim"].to_s)
      raise PayloadInvalido, "fim deve ser posterior ao início" unless fim > inicio

      new(
        consulta_id: envelope.consulta_id,
        estagiario_id: Integer(dados["estagiario_id"]),
        professor_id: Integer(dados["professor_id"]),
        sala: dados["sala"].to_s.squish,
        inicio: inicio,
        fim: fim,
        paciente_nome: dados["paciente_nome"].to_s.squish
      )
    rescue ArgumentError, TypeError => e
      raise PayloadInvalido, "valores inválidos em data: #{e.message}"
    end

    # Dados devolvidos nos eventos triagem.aprovada / triagem.reprovada.
    def to_event_data
      {
        "estagiario_id" => estagiario_id,
        "professor_id" => professor_id,
        "sala" => sala,
        "inicio" => inicio.utc.iso8601,
        "fim" => fim.utc.iso8601
      }
    end
  end
end
