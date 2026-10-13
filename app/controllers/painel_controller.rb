class PainelController < AreaRestritaController
  def index
    consultas = policy_scope(Consulta)
    @hoje = consultas.do_dia(Date.current).count
    @pendentes = consultas.futuras.where(status: :agendada).count
    @realizadas = consultas.where(status: :realizada).count
    @proximas = consultas.futuras.em_aberto.includes(:professor, :estagiario).order(:inicio).limit(5)
    @professores_ativos = policy_scope(Professor).ativos.count if current_usuario.admin?
  end
end
