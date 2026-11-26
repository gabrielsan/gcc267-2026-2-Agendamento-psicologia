require "rails_helper"

RSpec.describe Consultas::Saga::Cancelar do
  let(:consulta) { create(:consulta) }

  it "compensa uma reserva pendente de triagem com o motivo da reprovação" do
    resultado = described_class.call(consulta_id: consulta.id, motivo: "HORARIO_CONFLITANTE")

    expect(resultado).to eq(:cancelado)
    expect(consulta.reload).to be_cancelada
    evento = Messaging::OutboxEvent.last
    expect(evento).to have_attributes(event_type: "consulta.reserva_cancelada", consulta_id: consulta.id.to_s)
    expect(evento.data).to include("motivo" => "HORARIO_CONFLITANTE")
  end

  it "libera o horário: outra reserva pode ocupá-lo depois da compensação" do
    described_class.call(consulta_id: consulta.id, motivo: "x")

    outra = build(:consulta, estagiario: consulta.estagiario, sala: consulta.sala, inicio: consulta.inicio)
    expect(outra).to be_valid
    expect(Consultas::VerificadorConflito.new(outra).conflitos).to be_empty
  end

  it "ignora uma consulta que já saiu de pendente_triagem" do
    consulta.update!(status: :agendada)

    expect {
      expect(described_class.call(consulta_id: consulta.id, motivo: "tarde demais")).to eq(:ignorado)
    }.not_to change(Messaging::OutboxEvent, :count)
    expect(consulta.reload).to be_agendada
  end

  it "não inclui motivo no evento quando nenhum é informado" do
    described_class.call(consulta_id: consulta.id)

    expect(Messaging::OutboxEvent.last.data).not_to have_key("motivo")
  end
end
