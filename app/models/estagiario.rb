# == Schema Information
#
# Table name: usuarios
#
#  id                 :bigint           not null, primary key
#  ativo              :boolean          default(TRUE), not null
#  email              :string           default(""), not null
#  encrypted_password :string           default(""), not null
#  matricula          :string
#  nome               :string           not null
#  telefone           :string
#  type               :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  supervisor_id      :bigint
#
# Indexes
#
#  index_usuarios_on_email          (email) UNIQUE
#  index_usuarios_on_matricula      (matricula) UNIQUE WHERE (matricula IS NOT NULL)
#  index_usuarios_on_supervisor_id  (supervisor_id)
#  index_usuarios_on_type           (type)
#
# Foreign Keys
#
#  fk_rails_...  (supervisor_id => usuarios.id)
#
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
