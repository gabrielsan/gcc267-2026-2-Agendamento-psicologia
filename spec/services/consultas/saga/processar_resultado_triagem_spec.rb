require "rails_helper"

RSpec.describe Consultas::Saga::ProcessarResultadoTriagem do
  let(:consulta) { create(:consulta) }

  def envelope(event_type, data: {}, event_id: SecureRandom.uuid, consulta_id: consulta.id)
    {
      "event_id" => event_id, "event_type" => event_type, "consulta_id" => consulta_id.to_s,
      "occurred_at" => Time.current.iso8601(6), "version" => 1, "producer" => "triagem", "data" => data
    }
  end

  it "confirma a reserva em triagem.aprovada" do
    resultado = described_class.call(envelope("triagem.aprovada"))

    expect(resultado).to eq(:confirmado)
    expect(consulta.reload).to be_agendada
  end

  it "compensa a reserva em triagem.reprovada, repassando data.motivo" do
    resultado = described_class.call(envelope("triagem.reprovada", data: { "motivo" => "SALA_OCUPADA" }))

    expect(resultado).to eq(:cancelado)
    expect(consulta.reload).to be_cancelada
    expect(Messaging::OutboxEvent.last.data).to include("motivo" => "SALA_OCUPADA")
  end

  it "aceita motivo_detalhe/motivo_codigo como alternativa a data.motivo" do
    described_class.call(envelope("triagem.reprovada", data: { "motivo_codigo" => "SALA_OCUPADA", "motivo_detalhe" => "..." }))

    expect(Messaging::OutboxEvent.last.data).to include("motivo" => "SALA_OCUPADA")
  end

  it "é idempotente: o mesmo event_id não é processado duas vezes" do
    evento = envelope("triagem.aprovada")
    expect(described_class.call(evento)).to eq(:confirmado)

    expect(described_class.call(evento)).to eq(:evento_duplicado)
    expect(consulta.reload).to be_agendada
    expect(Messaging::OutboxEvent.where(event_type: "consulta.reserva_confirmada").count).to eq(1)
  end

  it "ignora um resultado para uma consulta que já saiu de pendente_triagem" do
    consulta.update!(status: :cancelada)

    expect(described_class.call(envelope("triagem.aprovada"))).to eq(:ignorado)
    expect(consulta.reload).to be_cancelada
  end

  it "recusa um tipo de evento inesperado" do
    expect { described_class.call(envelope("consulta.reserva_criada")) }.to raise_error(ArgumentError, /inesperado/)
  end

  it "registra o event_id processado mesmo quando a consulta é ignorada" do
    consulta.update!(status: :agendada)
    evento = envelope("triagem.aprovada")

    described_class.call(evento)

    expect(ProcessedEvent.find_by(event_id: evento["event_id"])).to be_present
  end
end
