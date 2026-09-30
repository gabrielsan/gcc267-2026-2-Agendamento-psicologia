class DashboardController < ApplicationController
  before_action :authenticate_actor!

  def index
    scope = dashboard_scope
    @upcoming_consultas = scope.includes(:estagiario, :professor).upcoming.limit(6)
    @consultas_count = scope.count
    @confirmed_count = scope.confirmada.count
    @professores_count = Professor.active.count
  end

  private

  def dashboard_scope
    return Consulta.all if admin_actor?
    return current_estagiario.consultas if estagiario_actor?
    return current_professor.consultas if professor_actor?

    Consulta.none
  end
end
