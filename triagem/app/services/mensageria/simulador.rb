module Mensageria
  # Ferramenta de demonstração: faz o papel do serviço de agendamento e publica
  # eventos no broker. Use com `bin/rails "triagem:simular[sucesso]"`.
  class Simulador
    CENARIOS = %w[sucesso sala_invalida supervisor_invalido conflito duplicada confirmar cancelar].freeze

    def initialize
      @conexao = Conexao.abrir
      @canal = @conexao.create_channel
      @canal.confirm_select
      Topologia.declarar(@canal) if Config.declarar_topologia?
      @exchange = Topologia.exchange(@canal)
      @sequencia = Time.now.to_i * 10
    end

    def executar(cenario, consulta_id: nil)
      case cenario
      when "sucesso"
        reserva_criada(novo_id, dados(horario))
      when "sala_invalida"
        reserva_criada(novo_id, dados(horario, "sala" => "Sala 99"))
      when "supervisor_invalido"
        reserva_criada(novo_id, dados(horario, "professor_id" => 3))
      when "conflito"
        inicio = horario
        reserva_criada(novo_id, dados(inicio))
        reserva_criada(novo_id, dados(inicio))
      when "duplicada"
        envelope = envelope_reserva(novo_id, dados(horario))
        2.times { publicar(envelope) }
      when "confirmar"
        desfecho("consulta.reserva_confirmada", consulta_id)
      when "cancelar"
        desfecho("consulta.reserva_cancelada", consulta_id)
      else
        raise ArgumentError, "cenário desconhecido: #{cenario}. Use: #{CENARIOS.join(', ')}"
      end
      @canal.wait_for_confirms
    ensure
      @conexao.close
    end

    private

    def novo_id
      @sequencia += 1
    end

    # Um horário aleatório nos próximos meses, dentro do expediente.
    def horario
      dia = Time.zone.now.beginning_of_day + rand(2..90).days
      dia.change(hour: rand(8..18))
    end

    def dados(inicio, extras = {})
      {
        "paciente_nome" => "Paciente de Teste",
        "estagiario_id" => 4,
        "professor_id" => 2,
        "sala" => "Sala 1",
        "inicio" => inicio.iso8601,
        "fim" => (inicio + 50.minutes).iso8601
      }.merge(extras)
    end

    def envelope_reserva(consulta_id, data)
      Envelope.montar(event_type: "consulta.reserva_criada", consulta_id: consulta_id, data: data)
    end

    def reserva_criada(consulta_id, data)
      publicar(envelope_reserva(consulta_id, data))
    end

    def desfecho(tipo, consulta_id)
      raise ArgumentError, "informe o consulta_id: triagem:simular[confirmar,123]" if consulta_id.blank?

      publicar(Envelope.montar(event_type: tipo, consulta_id: Integer(consulta_id), data: {}))
    end

    def publicar(envelope)
      @exchange.publish(envelope.to_json, routing_key: envelope["event_type"], persistent: true,
                                          message_id: envelope["event_id"], content_type: "application/json")
      puts "→ #{envelope['event_type']} consulta_id=#{envelope['consulta_id']} event_id=#{envelope['event_id']}"
    end
  end
end
