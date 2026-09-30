class Admin < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  validates :name, presence: true
end
