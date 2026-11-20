class Supervisao < ApplicationRecord
  self.table_name = "supervisoes"

  scope :ativas, -> { where(ativa: true) }
end
