class ApplicationController < ActionController::Base
  include Pundit::Authorization
  protect_from_forgery with: :exception, prepend: true
  before_action :verificar_conta_ativa
  before_action :nao_armazenar_paginas_privadas

  rescue_from Pundit::NotAuthorizedError do
    @titulo_erro = "Acesso não permitido"
    @mensagem_erro = "Seu perfil não tem acesso a esta ação ou a este registro."
    render "shared/erro", status: :forbidden
  end

  rescue_from ActiveRecord::RecordNotFound do
    @titulo_erro = "Registro não encontrado"
    @mensagem_erro = "Este registro pode ter sido excluído. Volte à lista para continuar."
    render "shared/erro", status: :not_found
  end

  private

  def pundit_user = current_usuario
  def after_sign_in_path_for(_resource) = painel_path
  def after_sign_out_path_for(_resource_or_scope) = root_path

  def verificar_conta_ativa
    return unless current_usuario && !current_usuario.ativo?

    sign_out(:usuario)
    redirect_to new_usuario_session_path, alert: "Sua conta está inativa. Procure a administração."
  end

  def nao_armazenar_paginas_privadas
    response.headers["Cache-Control"] = "no-store" if current_usuario || devise_controller?
  end
end
