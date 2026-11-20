# Dados de referência da triagem (idempotente).
#
# Os ids de estagiário/professor abaixo seguem os seeds do serviço de agendamento
# num banco novo (admin=1, Ana=2, Carlos=3, Maria=4, Pedro=5, Júlia=6).
# Confira no seu ambiente e ajuste se os ids forem diferentes.
["Sala 1", "Sala 2", "Sala 3"].each { |nome| Sala.find_or_create_by!(nome: nome) }

{ 4 => 2, 5 => 2, 6 => 3 }.each do |estagiario_id, professor_id|
  Supervisao.find_or_create_by!(estagiario_id: estagiario_id) { |s| s.professor_id = professor_id }
end

puts "Seeds da triagem: #{Sala.count} salas, #{Supervisao.count} supervisões."
