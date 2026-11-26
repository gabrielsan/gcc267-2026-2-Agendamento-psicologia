module Consultas
  class RegistrarEvento
    # motivo: preenchido na compensação (consulta.reserva_cancelada emitido
    # pela SAGA após triagem.reprovada); omitido dos demais eventos.
    def self.call(consulta, event_type, motivo: nil)
      dados = {
        estagiario_id: consulta.estagiario_id, professor_id: consulta.professor_id,
        inicio: consulta.inicio.iso8601(6), fim: consulta.fim.iso8601(6),
        sala: consulta.sala, status: consulta.status,
        paciente: { nome: consulta.paciente_nome, email: consulta.paciente_email, telefone: consulta.paciente_telefone }
      }
      dados[:motivo] = motivo if motivo.present?

      Messaging::Outbox.record!(event_type: event_type, consulta_id: consulta.id, data: dados)
    end
  end
end
