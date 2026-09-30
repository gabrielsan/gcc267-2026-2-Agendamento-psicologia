class Professor < ApplicationRecord
  self.table_name = "professors"

  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :consultas, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  validates :name, :email, :crp, presence: true
  validates :email, :crp, uniqueness: true
end
