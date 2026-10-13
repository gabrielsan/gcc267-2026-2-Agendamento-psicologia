class AreaRestritaController < ApplicationController
  before_action :authenticate_usuario!
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  class FiltroInvalido < StandardError; end

  rescue_from FiltroInvalido do |erro|
    @titulo_erro = "Confira os filtros"
    @mensagem_erro = erro.message
    render "shared/erro", status: :bad_request
  end

  private

  def paginar(relacao)
    pagina = params.fetch(:pagina, "1").to_s
    raise FiltroInvalido, "Informe um número de página válido." unless pagina.match?(/\A[1-9]\d{0,5}\z/)

    @total = relacao.count
    @paginas = [(@total / 12.0).ceil, 1].max
    @pagina = [pagina.to_i, @paginas].min
    relacao.limit(12).offset((@pagina - 1) * 12)
  end

  def data_do_filtro
    return if params[:data].blank?
    Date.iso8601(params[:data])
  rescue ArgumentError
    raise FiltroInvalido, "Informe uma data válida no formato AAAA-MM-DD."
  end
end
