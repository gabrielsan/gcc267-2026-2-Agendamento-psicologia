module Consultas
  # Cria uma consulta para um estagiário, aplicando as regras de agendamento:
  # validações do model, professor supervisor definido automaticamente e
  # verificação de conflito de horário (estagiário e sala).
  class Agendar
    CAMPOS = %w[paciente_nome paciente_telefone paciente_email inicio fim sala observacoes].freeze
    ERRO_CONFLITO_CONCORRENTE = "O horário acabou de ser ocupado por outra consulta. Escolha outro horário.".freeze

    def self.call(...)
      new(...).call
    end

    def initialize(estagiario:, params:)
      @estagiario = estagiario
      @params = params.to_h.stringify_keys.slice(*CAMPOS)
    end

    def call
      consulta = @estagiario.consultas.build(@params)
      consulta.status = :agendada

      return Resultado.falha(consulta.errors.full_messages, valor: consulta) unless consulta.valid?

      conflitos = VerificadorConflito.new(consulta).conflitos
      return Resultado.falha(conflitos, codigo: :conflito_horario, valor: consulta) if conflitos.any?

      Consulta.transaction(requires_new: true) { consulta.save! }
      Resultado.sucesso(consulta)
    rescue ActiveRecord::StatementInvalid => erro
      raise unless erro.cause.is_a?(PG::ExclusionViolation)

      # Outra requisição ocupou o horário entre a verificação e o save.
      Resultado.falha([ ERRO_CONFLITO_CONCORRENTE ], codigo: :conflito_horario, valor: consulta)
    end
  end
end
