require "rails_helper"
require "support/eventos"

RSpec.describe Mensageria::ProcessadorDeMensagem do
  include_context "dados de referencia"

  subject(:processador) { described_class.new }

  let(:corpo) do
    Mensageria::Envelope.montar(event_type: "consulta.reserva_criada", consulta_id: 10, data: dados_reserva).to_json
  end

  it "processa a mensagem e manda confirmar (ack)" do
    expect(processador.call(corpo)).to eq(:ack)
    expect(AvaliacaoTriagem.where(consulta_id: 10).count).to eq(1)
  end

  it "confirma a mensagem reentregue sem repetir o efeito" do
    processador.call(corpo)

    expect(processador.call(corpo, redelivered: true)).to eq(:ack)
    expect(AvaliacaoTriagem.where(consulta_id: 10).count).to eq(1)
    expect(OutboxEvent.where(consulta_id: 10).count).to eq(1)
  end

  it "manda mensagem inválida para a DLQ" do
    expect(processador.call("isso não é json")).to eq(:rejeitar)
  end

  it "ignora tipos de evento desconhecidos" do
    corpo_desconhecido = Mensageria::Envelope.montar(event_type: "outro.evento", consulta_id: 1, data: {}).to_json

    expect(processador.call(corpo_desconhecido)).to eq(:ack)
  end

  describe "erro inesperado" do
    let(:roteador) { instance_double(Mensageria::Roteador) }
    subject(:processador) { described_class.new(roteador: roteador) }

    before { allow(roteador).to receive(:call).and_raise(StandardError, "banco fora do ar") }

    it "reenfileira na primeira tentativa" do
      expect(processador.call(corpo)).to eq(:reenfileirar)
    end

    it "envia para a DLQ se já foi reentregue" do
      expect(processador.call(corpo, redelivered: true)).to eq(:rejeitar)
    end
  end
end
