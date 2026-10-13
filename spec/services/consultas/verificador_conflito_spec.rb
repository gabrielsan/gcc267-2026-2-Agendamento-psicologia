require "rails_helper"

RSpec.describe Consultas::VerificadorConflito do
  let(:existente) { create(:consulta, sala: "Sala 1") }

  def nova(**atributos)
    build(:consulta, { inicio: existente.inicio, fim: existente.fim, sala: "Sala 2" }.merge(atributos))
  end

  it "não acusa conflito em horários livres" do
    expect(described_class.new(nova(inicio: existente.fim, fim: existente.fim + 1.hour))).not_to be_conflito
  end

  it "acusa conflito do mesmo estagiário" do
    conflitos = described_class.new(nova(estagiario: existente.estagiario)).conflitos

    expect(conflitos).to contain_exactly(a_string_including("O estagiário já possui uma consulta"))
  end

  it "acusa conflito de sala" do
    conflitos = described_class.new(nova(sala: "Sala 1", inicio: existente.inicio + 20.minutes,
                                         fim: existente.fim + 20.minutes)).conflitos

    expect(conflitos).to contain_exactly(a_string_including('A sala "Sala 1" já está ocupada'))
  end

  it "ignora consultas canceladas" do
    existente.update!(status: :cancelada)

    expect(described_class.new(nova(estagiario: existente.estagiario, sala: "Sala 1"))).not_to be_conflito
  end

  it "não compara a consulta com ela mesma" do
    expect(described_class.new(existente)).not_to be_conflito
  end
end
