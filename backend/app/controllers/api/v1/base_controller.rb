module Api
  module V1
    # Base de todos os endpoints autenticados da API.
    #
    # - Exige um JWT válido (header "Authorization: Bearer <token>").
    # - Garante que toda ação passou pelo Pundit (authorize / policy_scope).
    # - Converte exceções comuns no formato de erro padrão.
    class BaseController < ApplicationController
      include Pundit::Authorization
      include Pagy::Backend

      POR_PAGINA_MAXIMO = 100

      class ParametroInvalido < StandardError; end

      # Os parâmetros devem vir com a chave raiz explícita, ex.: { "consulta": { ... } }
      wrap_parameters false

      before_action :autenticar!
      after_action :verify_authorized, unless: -> { action_name == "index" }
      after_action :verify_policy_scoped, if: -> { action_name == "index" }

      rescue_from ActiveRecord::RecordNotFound do
        render_erro("Registro não encontrado.", :not_found, codigo: :nao_encontrado)
      end

      rescue_from Pundit::NotAuthorizedError do
        render_erro("Você não tem permissão para realizar esta ação.", :forbidden, codigo: :sem_permissao)
      end

      rescue_from ActionController::ParameterMissing do |erro|
        render_erro("Parâmetro obrigatório ausente: #{erro.param}.", :bad_request, codigo: :parametro_ausente)
      end

      rescue_from Pagy::VariableError do
        render_erro("Parâmetros de paginação inválidos.", :bad_request, codigo: :parametro_invalido)
      end

      rescue_from ParametroInvalido do |erro|
        render_erro(erro.message, :bad_request, codigo: :parametro_invalido)
      end

      private

      def pundit_user
        current_usuario
      end

      def autenticar!
        return if current_usuario

        render_erro(I18n.t("devise.failure.unauthenticated"), :unauthorized, codigo: :nao_autenticado)
      end

      # Renderiza um Resultado de falha vindo de um service.
      def render_falha(resultado)
        render_erro(resultado.erros, :unprocessable_content, codigo: resultado.codigo)
      end

      def render_invalido(registro)
        render_erro(registro.errors.full_messages, :unprocessable_content, codigo: :invalido)
      end

      # Pagina uma relação e devolve [registros, meta].
      # Parâmetros: ?pagina=1&por_pagina=20
      def paginar(relacao)
        por_pagina = params.fetch(:por_pagina, 20).to_i.clamp(1, POR_PAGINA_MAXIMO)
        pagy, registros = pagy(relacao, limit: por_pagina, page: params.fetch(:pagina, 1))
        meta = { pagina: pagy.page, por_pagina: pagy.limit, total: pagy.count, paginas: pagy.pages }
        [ registros, meta ]
      end

      # Aceita data ("2026-10-07") ou data e hora ISO 8601.
      # Para datas puras, fim_do_dia: true devolve 23:59:59.
      def ler_data(valor, fim_do_dia: false)
        return if valor.blank?

        if valor.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
          data = Date.iso8601(valor)
          fim_do_dia ? data.in_time_zone.end_of_day : data.in_time_zone
        else
          Time.zone.iso8601(valor)
        end
      rescue ArgumentError # Date::Error é subclasse de ArgumentError
        raise ParametroInvalido, "Data ou hora em formato inválido: #{valor}. Use AAAA-MM-DD ou ISO 8601."
      end
    end
  end
end
