# Estagiário de Psicologia: realiza os atendimentos sob supervisão de um Professor.
class Estagiario < Usuario
  belongs_to :supervisor, class_name: "Professor", inverse_of: :estagiarios
  has_many :consultas, inverse_of: :estagiario, dependent: :restrict_with_error

  # Ao trocar de supervisor, as consultas ainda por acontecer passam a ser
  # supervisionadas pelo novo professor.
  after_update :transferir_consultas_futuras, if: :saved_change_to_supervisor_id?

  def estagiario? = true

  private

  def transferir_consultas_futuras
    consultas.futuras.em_aberto.update_all(professor_id: supervisor_id, updated_at: Time.current)
  end
end
