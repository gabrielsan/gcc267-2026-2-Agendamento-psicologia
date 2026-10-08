module Api
  # API stateless; os controllers HTML continuam usando ActionController::Base.
  class ApplicationController < ActionController::API
    private

    # A sessão HTML nunca autentica a API: mutações JSON não usam CSRF.
    # Decodificar o header também impede que um cookie prevaleça sobre outro JWT.
    def current_usuario
      return @usuario_jwt if defined?(@usuario_jwt)

      token = request.headers["Authorization"].to_s.match(/\ABearer (\S+)\z/i)&.captures&.first
      return @usuario_jwt = nil unless token

      usuario = Warden::JWTAuth::UserDecoder.new.call(token, :usuario, nil)
      @usuario_jwt = usuario if usuario.active_for_authentication?
    rescue JWT::DecodeError
      @usuario_jwt = nil
    end

    def render_erro(mensagens, status, codigo:)
      render json: { erros: Array(mensagens), codigo: codigo }, status: status
    end
  end
end
