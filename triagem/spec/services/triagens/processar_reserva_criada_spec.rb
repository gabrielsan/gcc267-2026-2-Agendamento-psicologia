require "rails_helper"
require "support/eventos"

RSpec.describe Triagens::ProcessarReservaCriada do
  include_context "dados de referencia"

  def processar(envelope)
    described_class.call(envelope: envelope)
  end

  def esperar_reprovada(envelope, codigo)
    expect(processar(envelope)).to eq(:processado)

    avaliacao = AvaliacaoTriagem.find_by!(consulta_id: envelope.consulta_id)
    expect(avaliacao.status).to eq("reprovada")
    expect(avaliacao.motivo_codigo).to eq(codigo)
    expect(ReservaTriagem.where(consulta_id: envelope.consulta_id)).to be_empty
    expect(Saga.find_by!(consulta_id: envelope.consulta_id).estado).to eq("TRIAGEM_REPROVADA")

    evento = OutboxEvent.find_by!(consulta_id: envelope.consulta_id)
    expect(evento.event_type).to eq("triagem.reprovada")
    expect(evento.payload["data"]).to include("motivo_codigo" => codigo)
  end

  describe "cenário de sucesso" do
    it "aprova, reserva o horário, avança a SAGA e grava triagem.aprovada na outbox" do
      envelope = montar_envelope(consulta_id: 10, data: dados_reserva)

      expect(processar(envelope)).to eq(:processado)

      expect(AvaliacaoTriagem.find_by!(consulta_id: 10).status).to eq("aprovada")
      expect(ReservaTriagem.ativas.where(consulta_id: 10).count).to eq(1)

      saga = Saga.find_by!(consulta_id: 10)
      expect(saga.estado).to eq("TRIAGEM_APROVADA")
      expect(saga.historico.map { |h| h["estado"] }).to eq(%w[AGUARDANDO_TRIAGEM TRIAGEM_APROVADA])

      evento = OutboxEvent.find_by!(consulta_id: 10)
      expect(evento.event_type).to eq("triagem.aprovada")
      expect(evento.published_at).to be_nil
      expect(evento.payload).to include("consulta_id" => 10, "causation_id" => envelope.event_id, "event_version" => 1)
    end
  end

  describe "cenários de falha" do
    it "reprova sala inexistente" do
      esperar_reprovada(montar_envelope(data: dados_reserva(sala: "Sala 99")), "SALA_INDISPONIVEL")
    end

    it "reprova sala inativa" do
      Sala.find_by!(nome: "Sala 1").update!(ativa: false)
      esperar_reprovada(montar_envelope(data: dados_reserva), "SALA_INDISPONIVEL")
    end

    it "reprova professor que não supervisiona o estagiário" do
      esperar_reprovada(montar_envelope(data: dados_reserva(professor_id: 3)), "SUPERVISOR_INVALIDO")
    end

    it "reprova estagiário sem supervisão cadastrada" do
      esperar_reprovada(montar_envelope(data: dados_reserva(estagiario_id: 99)), "SUPERVISOR_INVALIDO")
    end

    it "reprova horário fora do expediente" do
      esperar_reprovada(montar_envelope(data: dados_reserva(inicio: horario_futuro(hora: 21))), "FORA_DO_EXPEDIENTE")
    end

    it "reprova horário no passado" do
      esperar_reprovada(montar_envelope(data: dados_reserva(inicio: 2.hours.ago)), "HORARIO_NO_PASSADO")
    end

    it "reprova duração acima do máximo" do
      esperar_reprovada(montar_envelope(data: dados_reserva(duracao: 3.hours)), "DURACAO_INVALIDA")
    end

    it "reprova payload incompleto (e ainda assim compensa a reserva)" do
      esperar_reprovada(montar_envelope(data: dados_reserva.except("sala")), "PAYLOAD_INVALIDO")
    end

    it "reprova quando o estagiário já tem outra reserva aprovada no horário" do
      dados = dados_reserva
      processar(montar_envelope(consulta_id: 1, data: dados))

      esperar_reprovada(montar_envelope(consulta_id: 2, data: dados), "ESTAGIARIO_OCUPADO")
    end

    it "reprova quando a sala já está reservada no horário" do
      dados = dados_reserva
      processar(montar_envelope(consulta_id: 1, data: dados))

      esperar_reprovada(montar_envelope(consulta_id: 2, data: dados.merge("estagiario_id" => 5)), "SALA_OCUPADA")
    end
  end

  describe "reprocessamento (idempotência)" do
    it "não gera duas triagens nem dois eventos ao receber o mesmo event_id de novo" do
      envelope = montar_envelope(consulta_id: 10, data: dados_reserva)

      expect(processar(envelope)).to eq(:processado)
      expect(processar(envelope)).to eq(:evento_duplicado)
      expect(processar(envelope)).to eq(:evento_duplicado)

      expect(AvaliacaoTriagem.where(consulta_id: 10).count).to eq(1)
      expect(ReservaTriagem.where(consulta_id: 10).count).to eq(1)
      expect(OutboxEvent.where(consulta_id: 10).count).to eq(1)
      expect(ProcessedEvent.where(event_id: envelope.event_id).count).to eq(1)
    end

    it "não avalia de novo a mesma consulta que chega com outro event_id" do
      dados = dados_reserva

      expect(processar(montar_envelope(consulta_id: 10, data: dados))).to eq(:processado)
      expect(processar(montar_envelope(consulta_id: 10, data: dados))).to eq(:consulta_ja_avaliada)

      expect(AvaliacaoTriagem.where(consulta_id: 10).count).to eq(1)
      expect(OutboxEvent.where(consulta_id: 10).count).to eq(1)
    end
  end
end
