class ApplicationController < ActionController::Base
  helper_method :current_actor, :admin_actor?, :estagiario_actor?, :professor_actor?, :current_actor_role

  private

  def authenticate_actor!
    return if current_actor.present?

    redirect_to root_path, alert: "Escolha seu perfil para entrar."
  end

  def current_actor
    current_admin || current_estagiario || current_professor
  end

  def admin_actor?
    current_admin.present?
  end

  def estagiario_actor?
    current_estagiario.present?
  end

  def professor_actor?
    current_professor.present?
  end

  def current_actor_role
    return "Administração" if admin_actor?
    return "Estagiário" if estagiario_actor?
    return "Professor" if professor_actor?

    "Visitante"
  end

  def require_admin!
    return if admin_actor?

    redirect_to dashboard_path, alert: "Acesso restrito a administradores."
  end

  def require_estagiario!
    return if estagiario_actor?

    redirect_to dashboard_path, alert: "Ação disponível apenas para estagiários."
  end

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
