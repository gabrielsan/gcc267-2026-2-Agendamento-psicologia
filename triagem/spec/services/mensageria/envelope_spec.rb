require "rails_helper"
require "support/eventos"

RSpec.describe Mensageria::Envelope do
  let(:hash) { described_class.montar(event_type: "consulta.reserva_criada", consulta_id: 7, data: { "sala" => "Sala 1" }) }

  it "lê um evento válido" do
    envelope = described_class.parse(hash.to_json)

    expect(envelope.event_type).to eq("consulta.reserva_criada")
    expect(envelope.consulta_id).to eq(7)
    expect(envelope.event_version).to eq(1)
    expect(envelope.data).to eq("sala" => "Sala 1")
    expect(envelope.occurred_at).to be_a(Time)
  end

  it "rejeita JSON inválido" do
    expect { described_class.parse("{nao e json") }.to raise_error(Mensageria::EnvelopeInvalido, /JSON inválido/)
  end

  it "rejeita evento sem campos obrigatórios" do
    expect { described_class.parse(hash.except("consulta_id").to_json) }
      .to raise_error(Mensageria::EnvelopeInvalido, /consulta_id/)
  end

  it "rejeita event_id que não é UUID" do
    expect { described_class.parse(hash.merge("event_id" => "123").to_json) }
      .to raise_error(Mensageria::EnvelopeInvalido, /UUID/)
  end

  it "rejeita versão não suportada" do
    expect { described_class.parse(hash.merge("event_version" => 99).to_json) }
      .to raise_error(Mensageria::EnvelopeInvalido, /versão/)
  end
end
