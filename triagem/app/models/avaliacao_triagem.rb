class AvaliacaoTriagem < ApplicationRecord
  self.table_name = "avaliacoes_triagem"

  def aprovada?
    status == "aprovada"
  end

  def reprovada?
    status == "reprovada"
  end
end
