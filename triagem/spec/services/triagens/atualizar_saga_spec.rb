require "rails_helper"
require "support/eventos"

RSpec.describe Triagens::AtualizarSaga do
  include_context "dados de referencia"

  let(:dados) { dados_reserva }

  def criar_reserva(consulta_id, dados_da_reserva = dados)
    Triagens::ProcessarReservaCriada.call(envelope: montar_envelope(consulta_id: consulta_id, data: dados_da_reserva))
  end

  def atualizar(tipo, consulta_id, envelope: nil)
    envelope ||= montar_envelope(tipo: tipo, consulta_id: consulta_id)
    described_class.call(envelope: envelope)
  end

  it "marca a SAGA como CONFIRMADA e mantém o horário reservado" do
    criar_reserva(10)

    expect(atualizar("consulta.reserva_confirmada", 10)).to eq(:processado)

    expect(Saga.find_by!(consulta_id: 10).estado).to eq("CONFIRMADA")
    expect(ReservaTriagem.ativas.where(consulta_id: 10).count).to eq(1)
  end

  it "compensa: reserva reprovada e cancelada leva a SAGA para COMPENSADA" do
    criar_reserva(10, dados.merge("sala" => "Sala 99"))
    expect(Saga.find_by!(consulta_id: 10).estado).to eq("TRIAGEM_REPROVADA")

    atualizar("consulta.reserva_cancelada", 10)

    saga = Saga.find_by!(consulta_id: 10)
    expect(saga.estado).to eq("COMPENSADA")
    expect(saga.motivo_falha).to eq("SALA_INDISPONIVEL")
  end

  it "libera o horário quando uma reserva aprovada é cancelada" do
    criar_reserva(10)
    expect(criar_reserva(11)).to eq(:processado)
    expect(AvaliacaoTriagem.find_by!(consulta_id: 11).motivo_codigo).to eq("ESTAGIARIO_OCUPADO")

    atualizar("consulta.reserva_cancelada", 10)

    expect(Saga.find_by!(consulta_id: 10).estado).to eq("CANCELADA")
    expect(ReservaTriagem.ativas.where(consulta_id: 10)).to be_empty

    # O mesmo horário volta a ficar disponível para outra consulta.
    criar_reserva(12)
    expect(AvaliacaoTriagem.find_by!(consulta_id: 12).status).to eq("aprovada")
  end

  it "é idempotente: o mesmo event_id não altera a SAGA duas vezes" do
    criar_reserva(10)
    envelope = montar_envelope(tipo: "consulta.reserva_confirmada", consulta_id: 10)

    expect(atualizar(nil, 10, envelope: envelope)).to eq(:processado)
    expect(atualizar(nil, 10, envelope: envelope)).to eq(:evento_duplicado)

    expect(Saga.find_by!(consulta_id: 10).historico.size).to eq(3)
  end

  it "ignora transição inválida (confirmar depois de compensar)" do
    criar_reserva(10, dados.merge("sala" => "Sala 99"))
    atualizar("consulta.reserva_cancelada", 10)

    atualizar("consulta.reserva_confirmada", 10)

    expect(Saga.find_by!(consulta_id: 10).estado).to eq("COMPENSADA")
  end

  it "levanta erro quando a SAGA ainda não existe" do
    expect { atualizar("consulta.reserva_confirmada", 999) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(ProcessedEvent.count).to eq(0)
  end
end
