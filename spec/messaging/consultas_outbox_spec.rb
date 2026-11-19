require "rails_helper"

RSpec.describe "Transactional consultation events" do
  let(:estagiario) { create(:estagiario) }
  let(:inicio) { 3.days.from_now.change(hour: 10) }
  let(:params) { { paciente_nome: "Paciente Teste", inicio: inicio, fim: inicio + 50.minutes, sala: "Sala 88" } }

  it "saves consultation and reserva_criada together" do
    result = Consultas::Agendar.call(estagiario: estagiario, params: params)
    event = Messaging::OutboxEvent.last
    expect(result).to be_sucesso
    expect(event).to have_attributes(consulta_id: result.valor.id.to_s, event_type: "consulta.reserva_criada", published_at: nil)
    expect(event.data).to include("sala" => "Sala 88", "professor_id" => estagiario.supervisor_id)
  end

  it "does not save the consultation if the outbox write fails" do
    estagiario
    allow(Messaging::Outbox).to receive(:record!).and_raise("database failure")
    expect {
      expect { Consultas::Agendar.call(estagiario: estagiario, params: params) }.to raise_error("database failure")
    }.not_to change(Consulta, :count)
  end

  it "does not emit an event for invalid consultations" do
    expect {
      Consultas::Agendar.call(estagiario: estagiario, params: params.merge(paciente_nome: ""))
    }.not_to change(Messaging::OutboxEvent, :count)
  end

  it "emits confirmation and cancellation only for status changes" do
    consulta = create(:consulta)
    Consultas::Atualizar.call(consulta: consulta, usuario: consulta.professor, params: { status: "confirmada" })
    expect(Messaging::OutboxEvent.last.event_type).to eq("consulta.reserva_confirmada")
    expect {
      Consultas::Atualizar.call(consulta: consulta, usuario: consulta.professor, params: { observacoes: "OK" })
    }.not_to change(Messaging::OutboxEvent, :count)
    Consultas::Atualizar.call(consulta: consulta, usuario: consulta.estagiario, params: { status: "cancelada" })
    expect(Messaging::OutboxEvent.last.event_type).to eq("consulta.reserva_cancelada")
  end
end
