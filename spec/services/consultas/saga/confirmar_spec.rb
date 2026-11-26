require "rails_helper"

RSpec.describe Consultas::Saga::Confirmar do
  let(:consulta) { create(:consulta) }

  it "confirma uma reserva pendente de triagem e emite consulta.reserva_confirmada" do
    resultado = described_class.call(consulta_id: consulta.id)

    expect(resultado).to eq(:confirmado)
    expect(consulta.reload).to be_agendada
    evento = Messaging::OutboxEvent.last
    expect(evento).to have_attributes(event_type: "consulta.reserva_confirmada", consulta_id: consulta.id.to_s)
    expect(evento.data).not_to have_key("motivo")
  end

  it "ignora uma consulta que já saiu de pendente_triagem" do
    consulta.update!(status: :cancelada)

    expect {
      expect(described_class.call(consulta_id: consulta.id)).to eq(:ignorado)
    }.not_to change(Messaging::OutboxEvent, :count)
    expect(consulta.reload).to be_cancelada
  end
end
