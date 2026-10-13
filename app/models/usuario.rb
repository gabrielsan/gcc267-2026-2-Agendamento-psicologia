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
# Base de todos os usuários do sistema (STI pela coluna "type").
# Não deve ser instanciada diretamente: use Admin, Professor ou Estagiario.
class Usuario < ApplicationRecord
  TIPOS = %w[Admin Professor Estagiario].freeze

  devise :database_authenticatable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :nome, with: ->(nome) { nome.squish }

  validates :nome, presence: true, length: { maximum: 120 }
  validates :type, inclusion: { in: TIPOS }
  validates :matricula, uniqueness: true, allow_blank: true
  validates :telefone, length: { maximum: 20 }, allow_blank: true

  scope :ativos, -> { where(ativo: true) }
  scope :busca, ->(termo) {
    where("usuarios.nome ILIKE :t OR usuarios.email ILIKE :t", t: "%#{sanitize_sql_like(termo)}%")
  }

  # "admin", "professor" ou "estagiario"
  def papel
    type.to_s.underscore
  end

  def admin? = false
  def professor? = false
  def estagiario? = false

  # Usuários desativados pelo admin não conseguem fazer login.
  def active_for_authentication?
    super && ativo?
  end

  def inactive_message
    ativo? ? super : :inativo
  end
end
