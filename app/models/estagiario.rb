class Estagiario < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :consultas, dependent: :restrict_with_error

  validates :name, :registration, presence: true
  validates :registration, uniqueness: true
end
