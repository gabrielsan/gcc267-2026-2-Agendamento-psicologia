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
