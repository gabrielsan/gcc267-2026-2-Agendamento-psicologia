module Api
  module V1
    # Login e logout com JWT (devise-jwt).
    #
    # POST /api/v1/login   { "email": "...", "senha": "..." }
    #   => 200, corpo { "usuario": {...} } e header "Authorization: Bearer <token>"
    # DELETE /api/v1/logout (com o header Authorization)
    #   => 204; o token é revogado (vai para a jwt_denylists)
    #
    # A emissão e a revogação do token são feitas pelo middleware do devise-jwt,
    # configurado em config/initializers/devise.rb.
    class SessoesController < Api::ApplicationController
      def create
        usuario = Usuario.find_for_authentication(email: params[:email].to_s.strip.downcase)

        unless usuario&.valid_password?(params[:senha].to_s)
          return render_erro(I18n.t("devise.failure.invalid"), :unauthorized, codigo: :credenciais_invalidas)
        end

        unless usuario.active_for_authentication?
          return render_erro(I18n.t("devise.failure.inativo"), :unauthorized, codigo: :usuario_inativo)
        end

        # store: false => sem sessão/cookie; o devise-jwt gera o token neste momento.
        warden.set_user(usuario, scope: :usuario, store: false, event: :authentication)
        render json: { usuario: UsuarioSerializer.new(usuario).as_json }
      end

      def destroy
        return render_erro(I18n.t("devise.failure.unauthenticated"), :unauthorized, codigo: :nao_autenticado) unless current_usuario

        head :no_content
      end
    end
  end
end
