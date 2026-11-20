class Sala < ApplicationRecord
  scope :ativas, -> { where(ativa: true) }
end
