require "rails_helper"
require "support/eventos"
require "support/broker_falso"

RSpec.describe Mensageria::Publicador do
  let(:exchange) { ExchangeFalso.new }
  let(:canal) { CanalFalso.new }

  subject(:publicador) { described_class.new(canal: canal, exchange: exchange) }

  def registrar_evento(consulta_id, tipo = "triagem.aprovada")
    OutboxEvent.registrar!(event_type: tipo, consulta_id: consulta_id, data: { "sala" => "Sala 1" })
  end

  it "publica os pendentes com a routing key do tipo e marca published_at" do
    evento = registrar_evento(1)

    expect(publicador.publicar_pendentes).to eq(1)

    publicada = exchange.publicadas.first
    expect(publicada[:opcoes]).to include(routing_key: "triagem.aprovada", persistent: true, message_id: evento.event_id)
    expect(JSON.parse(publicada[:corpo])).to include("event_id" => evento.event_id, "consulta_id" => 1)
    expect(evento.reload.published_at).to be_present
  end

  it "não publica de novo o que já foi publicado" do
    registrar_evento(1)
    publicador.publicar_pendentes

    expect(publicador.publicar_pendentes).to eq(0)
    expect(exchange.publicadas.size).to eq(1)
  end

  it "publica na ordem em que os eventos foram gravados" do
    registrar_evento(1)
    registrar_evento(2, "triagem.reprovada")

    publicador.publicar_pendentes

    expect(exchange.publicadas.map { |p| p[:opcoes][:routing_key] }).to eq(%w[triagem.aprovada triagem.reprovada])
  end

  it "mantém o evento pendente se o broker não confirmar" do
    evento = registrar_evento(1)
    publicador = described_class.new(canal: CanalFalso.new(confirma: false), exchange: exchange)

    expect { publicador.publicar_pendentes }.to raise_error(Mensageria::FalhaPublicacao)
    expect(evento.reload.published_at).to be_nil
  end
end
