# Plurais em português que o Inflector (em inglês) não acerta sozinho.
# Ex.: sem isso, "professor".pluralize vira "professors" e "consulta" não muda.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "professor", "professores"
  inflect.irregular "consulta", "consultas"
end
