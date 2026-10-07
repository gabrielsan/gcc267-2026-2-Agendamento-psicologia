module Consultas
  # Edita uma consulta respeitando o que cada papel pode alterar, as transições
  # de status permitidas e os conflitos de horário.
  #
  # A permissão de editar *esta* consulta é checada antes, na ConsultaPolicy;
  # aqui ficam as regras sobre *o que* pode ser alterado.
  class Atualizar
    CAMPOS_DO_PACIENTE_E_HORARIO = %w[paciente_nome paciente_telefone paciente_email inicio fim sala].freeze

    CAMPOS_POR_PAPEL = {
      "admin" => [ "estagiario_id", *CAMPOS_DO_PACIENTE_E_HORARIO, "status", "observacoes" ],
      "professor" => %w[status observacoes],
      "estagiario" => [ *CAMPOS_DO_PACIENTE_E_HORARIO, "status", "observacoes" ]
    }.freeze

    # Status que cada papel pode atribuir (nil = qualquer transição válida).
    STATUS_POR_PAPEL = {
      "admin" => nil,
      "professor" => nil,
      "estagiario" => %w[cancelada realizada falta]
    }.freeze

    CAMPOS_QUE_AFETAM_HORARIO = %w[inicio fim sala estagiario_id].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(consulta:, params:, usuario:)
      @consulta = consulta
      @params = params.to_h.stringify_keys
      @usuario = usuario
    end

    def call
      if (proibidos = campos_proibidos).any?
        return falha("#{@usuario.model_name.human} não pode alterar: #{nomes(proibidos)}.", :campo_nao_permitido)
      end

      @consulta.assign_attributes(@params)

      if status_proibido?
        return falha("#{@usuario.model_name.human} não pode marcar a consulta como #{@consulta.status}.", :status_nao_permitido)
      end

      return falha(@consulta.errors.full_messages) unless @consulta.valid?

      if afeta_horario? && (conflitos = VerificadorConflito.new(@consulta).conflitos).any?
        return falha(conflitos, :conflito_horario)
      end

      @consulta.save!
      Resultado.sucesso(@consulta)
    rescue ActiveRecord::ExclusionViolation
      falha(Agendar::ERRO_CONFLITO_CONCORRENTE, :conflito_horario)
    end

    private

    def campos_proibidos
      @params.keys - CAMPOS_POR_PAPEL.fetch(@usuario.papel, [])
    end

    def status_proibido?
      permitidos = STATUS_POR_PAPEL.fetch(@usuario.papel, [])
      !permitidos.nil? && @consulta.will_save_change_to_status? && !permitidos.include?(@consulta.status)
    end

    def afeta_horario?
      CAMPOS_QUE_AFETAM_HORARIO.any? { |campo| @consulta.will_save_change_to_attribute?(campo) }
    end

    def nomes(campos)
      campos.map { |campo| Consulta.human_attribute_name(campo) }.join(", ")
    end

    def falha(erros, codigo = :invalido)
      Resultado.falha(erros, codigo: codigo, valor: @consulta)
    end
  end
end
