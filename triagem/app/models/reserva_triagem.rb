class ReservaTriagem < ApplicationRecord
  self.table_name = "reservas_triagem"

  scope :ativas, -> { where(ativa: true) }
  scope :sobrepostas, ->(inicio, fim) { where("reservas_triagem.inicio < ? AND reservas_triagem.fim > ?", fim, inicio) }
end
