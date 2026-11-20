module Mensageria
  # Formato comum de todos os eventos (contrato da etapa):
  #
  #   {
  #     "event_id":      "uuid",
  #     "event_type":    "consulta.reserva_criada",
  #     "event_version": 1,
  #     "consulta_id":   42,
  #     "occurred_at":   "2026-11-19T10:00:00.000Z",
  #     "causation_id":  "uuid do evento que causou este (opcional)",
  #     "data":          { ...dados do evento... }
  #   }
  class Envelope
    VERSOES_SUPORTADAS = [ 1 ].freeze
    CAMPOS_OBRIGATORIOS = %w[event_id event_type event_version consulta_id occurred_at data].freeze
    UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

    attr_reader :event_id, :event_type, :event_version, :consulta_id, :occurred_at, :causation_id, :data

    def self.parse(json)
      hash = JSON.parse(json)
      raise EnvelopeInvalido, "o corpo da mensagem deve ser um objeto JSON" unless hash.is_a?(Hash)

      from_hash(hash)
    rescue JSON::ParserError => e
      raise EnvelopeInvalido, "JSON inválido: #{e.message}"
    end

    def self.from_hash(hash)
      campos = hash.to_h.stringify_keys
      ausentes = CAMPOS_OBRIGATORIOS.select { |campo| campos[campo].nil? }
      raise EnvelopeInvalido, "campos ausentes: #{ausentes.join(', ')}" if ausentes.any?
      raise EnvelopeInvalido, "event_id deve ser um UUID" unless campos["event_id"].to_s.match?(UUID)
      raise EnvelopeInvalido, "event_version #{campos['event_version']} não suportada" unless VERSOES_SUPORTADAS.include?(campos["event_version"])
      raise EnvelopeInvalido, "data deve ser um objeto" unless campos["data"].is_a?(Hash)

      new(
        event_id: campos["event_id"],
        event_type: campos["event_type"].to_s,
        event_version: campos["event_version"],
        consulta_id: Integer(campos["consulta_id"]),
        occurred_at: Time.iso8601(campos["occurred_at"].to_s),
        causation_id: campos["causation_id"],
        data: campos["data"]
      )
    rescue ArgumentError, TypeError => e
      raise EnvelopeInvalido, "valor inválido no envelope: #{e.message}"
    end

    # Monta o hash (pronto para virar JSON) de um novo evento.
    def self.montar(event_type:, consulta_id:, data:, causation_id: nil, event_id: SecureRandom.uuid,
                    event_version: 1, occurred_at: Time.current)
      {
        "event_id" => event_id,
        "event_type" => event_type,
        "event_version" => event_version,
        "consulta_id" => consulta_id,
        "occurred_at" => occurred_at.utc.iso8601(3),
        "causation_id" => causation_id,
        "data" => data
      }.compact
    end

    def initialize(event_id:, event_type:, event_version:, consulta_id:, occurred_at:, data:, causation_id: nil)
      @event_id = event_id
      @event_type = event_type
      @event_version = event_version
      @consulta_id = consulta_id
      @occurred_at = occurred_at
      @causation_id = causation_id
      @data = data
    end
  end
end
