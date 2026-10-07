require "rails_helper"

RSpec.describe Consultas::Agendar do
  let(:estagiario) { create(:estagiario) }
  let(:inicio) { 3.days.from_now.change(hour: 9, min: 0) }
  let(:params) do
    { paciente_nome: "João da Silva", sala: "Sala 1", inicio: inicio, fim: inicio + 50.minutes }
  end

  it "cria a consulta agendada com o supervisor do estagiário" do
    resultado = described_class.call(estagiario: estagiario, params: params)

    expect(resultado).to be_sucesso
    expect(resultado.valor).to be_persisted
    expect(resultado.valor).to have_attributes(status: "agendada", estagiario: estagiario, professor: estagiario.supervisor)
  end

  it "ignora campos que o estagiário não define na criação" do
    outro = create(:estagiario)
    resultado = described_class.call(estagiario: estagiario,
                                     params: params.merge(status: "realizada", estagiario_id: outro.id))

    expect(resultado.valor).to have_attributes(status: "agendada", estagiario_id: estagiario.id)
  end

  it "devolve erros de validação" do
    resultado = described_class.call(estagiario: estagiario, params: params.merge(paciente_nome: ""))

    expect(resultado).to be_falha
    expect(resultado.codigo).to eq(:invalido)
    expect(resultado.erros).to include("Nome do paciente não pode ficar em branco")
  end

  it "recusa horário em conflito" do
    described_class.call(estagiario: estagiario, params: params)
    resultado = described_class.call(estagiario: estagiario,
                                     params: params.merge(sala: "Sala 2", inicio: inicio + 30.minutes, fim: inicio + 80.minutes))

    expect(resultado).to be_falha
    expect(resultado.codigo).to eq(:conflito_horario)
    expect(Consulta.count).to eq(1)
  end

  it "trata o conflito detectado pelo banco (requisições simultâneas)" do
    allow_any_instance_of(Consultas::VerificadorConflito).to receive(:conflitos).and_return([])
    described_class.call(estagiario: estagiario, params: params)

    resultado = described_class.call(estagiario: estagiario, params: params)

    expect(resultado.codigo).to eq(:conflito_horario)
    expect(resultado.erros).to eq([ described_class::ERRO_CONFLITO_CONCORRENTE ])
  end
end
