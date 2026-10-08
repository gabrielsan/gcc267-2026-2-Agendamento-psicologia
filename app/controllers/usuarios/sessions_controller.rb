module Usuarios
  class SessionsController < Devise::SessionsController
    before_action :definir_perfil, only: %i[new create]

    private

    def definir_perfil
      @perfil = params[:perfil].presence_in(%w[professor estagiario admin])
    end
  end
end
