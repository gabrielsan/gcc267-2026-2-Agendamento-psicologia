module Api
  # API stateless; os controllers HTML continuam usando ActionController::Base.
  class ApplicationController < ActionController::API
    private

    def render_erro(mensagens, status, codigo:)
      render json: { erros: Array(mensagens), codigo: codigo }, status: status
    end
  end
end
