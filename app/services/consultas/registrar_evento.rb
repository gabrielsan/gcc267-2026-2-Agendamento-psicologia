module Consultas
  class RegistrarEvento
    def self.call(consulta, event_type)
      Messaging::Outbox.record!(event_type: event_type, consulta_id: consulta.id, data: {
        estagiario_id: consulta.estagiario_id, professor_id: consulta.professor_id,
        inicio: consulta.inicio.iso8601(6), fim: consulta.fim.iso8601(6),
        sala: consulta.sala, status: consulta.status,
        paciente: { nome: consulta.paciente_nome, email: consulta.paciente_email, telefone: consulta.paciente_telefone }
      })
    end
  end
end
