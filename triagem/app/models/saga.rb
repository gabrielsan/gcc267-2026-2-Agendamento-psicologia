# Estado da SAGA de uma reserva, do ponto de vista da triagem.
#
#   AGUARDANDO_TRIAGEM ─▶ TRIAGEM_APROVADA ─▶ CONFIRMADA
#                     │            └────────▶ CANCELADA   (cancelamento posterior)
#                     ├─▶ TRIAGEM_REPROVADA ─▶ COMPENSADA  (reserva cancelada pelo agendamento)
#                     └─▶ CANCELADA
class Saga < ApplicationRecord
  ESTADOS = %w[AGUARDANDO_TRIAGEM TRIAGEM_APROVADA TRIAGEM_REPROVADA CONFIRMADA COMPENSADA CANCELADA].freeze

  TRANSICOES = {
    "AGUARDANDO_TRIAGEM" => %w[TRIAGEM_APROVADA TRIAGEM_REPROVADA CANCELADA],
    "TRIAGEM_APROVADA" => %w[CONFIRMADA CANCELADA],
    "TRIAGEM_REPROVADA" => %w[COMPENSADA],
    "CONFIRMADA" => %w[CANCELADA],
    "COMPENSADA" => [],
    "CANCELADA" => []
  }.freeze

  validates :estado, inclusion: { in: ESTADOS }

  def self.iniciar!(consulta_id:, event_id:)
    create!(consulta_id: consulta_id, estado: "AGUARDANDO_TRIAGEM",
            historico: [ registro("AGUARDANDO_TRIAGEM", event_id) ])
  end

  def self.registro(estado, event_id)
    { "estado" => estado, "event_id" => event_id, "em" => Time.current.iso8601(3) }
  end

  def pode_avancar_para?(novo_estado)
    TRANSICOES.fetch(estado).include?(novo_estado)
  end

  # Devolve false (sem alterar nada) se a transição não é permitida.
  def avancar!(novo_estado, event_id:, motivo: nil)
    return false unless pode_avancar_para?(novo_estado)

    update!(estado: novo_estado,
            motivo_falha: motivo || motivo_falha,
            historico: historico + [ self.class.registro(novo_estado, event_id) ])
    true
  end
end
