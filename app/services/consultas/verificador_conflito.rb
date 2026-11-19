module Consultas
  # Procura choques de horário de uma consulta com as demais consultas ativas
  # (não canceladas): o mesmo estagiário ou a mesma sala no mesmo período.
  #
  # O banco também impede conflitos (exclusion constraints); este verificador
  # existe para devolver mensagens claras antes de tentar salvar.
  class VerificadorConflito
    attr_reader :consulta

    def initialize(consulta)
      @consulta = consulta
    end

    def conflito?
      conflitos.any?
    end

    # Lista de mensagens legíveis (vazia quando não há conflito).
    def conflitos
      return [] if consulta.cancelada? || consulta.inicio.blank? || consulta.fim.blank?

      [ conflito_do_estagiario, conflito_da_sala ].compact
    end

    private

    def concorrentes
      Consulta.ativas.sobrepostas(consulta.inicio, consulta.fim).where.not(id: consulta.id).order(:inicio)
    end

    def conflito_do_estagiario
      return if consulta.estagiario_id.blank?

      outra = concorrentes.find_by(estagiario_id: consulta.estagiario_id)
      "O estagiário já possui uma consulta #{periodo(outra)}." if outra
    end

    def conflito_da_sala
      return if consulta.sala.blank?

      outra = concorrentes.find_by(sala: consulta.sala)
      "A sala \"#{consulta.sala}\" já está ocupada #{periodo(outra)}." if outra
    end

    def periodo(outra)
      "em #{I18n.l(outra.inicio, format: '%d/%m/%Y')} das #{I18n.l(outra.inicio, format: '%H:%M')} " \
        "às #{I18n.l(outra.fim, format: '%H:%M')}"
    end
  end
end
