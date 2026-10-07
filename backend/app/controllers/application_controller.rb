class ApplicationController < ActionController::API
  private

  # Formato único de erro da API: { "erros": [...], "codigo": "..." }
  def render_erro(mensagens, status, codigo:)
    render json: { erros: Array(mensagens), codigo: codigo }, status: status
  end
end
