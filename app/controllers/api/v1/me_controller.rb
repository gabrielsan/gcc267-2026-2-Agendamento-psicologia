module Api
  module V1
    # GET /api/v1/me — dados do usuário logado (útil para o frontend saber o papel).
    class MeController < BaseController
      def show
        skip_authorization
        render json: { usuario: UsuarioSerializer.new(current_usuario).as_json }
      end
    end
  end
end
