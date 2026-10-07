require "rails_helper"

RSpec.describe Consultas::Atualizar do
  let(:consulta) { create(:consulta) }
  let(:estagiario) { consulta.estagiario }
  let(:professor) { consulta.professor }
  let(:admin) { create(:admin) }

  def atualizar(usuario, params)
    described_class.call(consulta: consulta, params: params, usuario: usuario)
  end

  describe "campos por papel" do
    it "estagiário altera dados do paciente e horário" do
      resultado = atualizar(estagiario, paciente_nome: "Novo Nome", sala: "Sala 99")

      expect(resultado).to be_sucesso
      expect(consulta.reload).to have_attributes(paciente_nome: "Novo Nome", sala: "Sala 99")
    end

    it "professor altera status e observações" do
      resultado = atualizar(professor, status: "confirmada", observacoes: "Ok")

      expect(resultado).to be_sucesso
      expect(consulta.reload).to have_attributes(status: "confirmada", observacoes: "Ok")
    end

    it "professor não altera horário nem sala" do
      resultado = atualizar(professor, sala: "Outra")

      expect(resultado.codigo).to eq(:campo_nao_permitido)
      expect(resultado.erros.first).to include("Sala")
      expect(consulta.reload.sala).not_to eq("Outra")
    end

    it "estagiário não troca o estagiário da consulta" do
      expect(atualizar(estagiario, estagiario_id: create(:estagiario).id).codigo).to eq(:campo_nao_permitido)
    end

    it "admin pode reatribuir a outro estagiário, e o professor acompanha" do
      outro = create(:estagiario)
      resultado = atualizar(admin, estagiario_id: outro.id)

      expect(resultado).to be_sucesso
      expect(consulta.reload).to have_attributes(estagiario: outro, professor: outro.supervisor)
    end
  end

  describe "status" do
    it "estagiário pode cancelar" do
      expect(atualizar(estagiario, status: "cancelada")).to be_sucesso
    end

    it "estagiário não pode confirmar (é papel do professor)" do
      expect(atualizar(estagiario, status: "confirmada").codigo).to eq(:status_nao_permitido)
    end

    it "respeita as transições do model" do
      consulta.update!(status: :cancelada)
      resultado = atualizar(professor, status: "confirmada")

      expect(resultado.codigo).to eq(:invalido)
      expect(resultado.erros.first).to include("não pode mudar de cancelada para confirmada")
    end
  end

  describe "conflitos" do
    it "trata conflitos detectados pelo banco e preserva a consulta original" do
      outra = create(:consulta, estagiario: estagiario, inicio: consulta.inicio + 2.hours)
      inicio_original = consulta.inicio
      allow_any_instance_of(Consultas::VerificadorConflito).to receive(:conflitos).and_return([])

      resultado = atualizar(estagiario, inicio: outra.inicio, fim: outra.fim)

      expect(resultado.codigo).to eq(:conflito_horario)
      expect(consulta.reload.inicio).to eq(inicio_original)
      expect(Consulta.count).to eq(2)
    end

    it "recusa mudar para um horário ocupado" do
      outra = create(:consulta, estagiario: estagiario, inicio: consulta.inicio + 2.hours)
      resultado = atualizar(estagiario, inicio: outra.inicio, fim: outra.fim)

      expect(resultado.codigo).to eq(:conflito_horario)
    end

    it "não verifica conflito quando o horário não muda" do
      expect(Consultas::VerificadorConflito).not_to receive(:new)
      atualizar(professor, observacoes: "Sem mudança de horário")
    end
  end
end
