# Helpers para montar eventos e dados de referência nos testes.
module EventosHelper
  def horario_futuro(hora: 10, dias: 3)
    Time.zone.now.change(hour: hora, min: 0, sec: 0) + dias.days
  end

  def dados_reserva(inicio: horario_futuro, duracao: 50.minutes, **extras)
    {
      "paciente_nome" => "João da Silva",
      "estagiario_id" => 4,
      "professor_id" => 2,
      "sala" => "Sala 1",
      "inicio" => inicio.iso8601,
      "fim" => (inicio + duracao).iso8601
    }.merge(extras.transform_keys(&:to_s))
  end

  def montar_envelope(tipo: "consulta.reserva_criada", consulta_id: 10, data: {}, event_id: SecureRandom.uuid)
    hash = Mensageria::Envelope.montar(event_type: tipo, consulta_id: consulta_id, data: data, event_id: event_id)
    Mensageria::Envelope.from_hash(hash)
  end
end

RSpec.configure { |config| config.include EventosHelper }

RSpec.shared_context "dados de referencia" do
  before do
    Sala.create!(nome: "Sala 1")
    Sala.create!(nome: "Sala 2")
    Supervisao.create!(estagiario_id: 4, professor_id: 2)
    Supervisao.create!(estagiario_id: 5, professor_id: 2)
  end
end
