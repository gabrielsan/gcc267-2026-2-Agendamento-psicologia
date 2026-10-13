# Dados de exemplo para desenvolvimento. Pode rodar várias vezes (idempotente):
#   docker compose run --rm web bin/rails db:seed
#
# Todos os usuários usam a senha "senha123".

# Os testes criam os próprios dados; seeds no banco de teste quebram as specs.
return if Rails.env.test?

SENHA = "senha123".freeze

def usuario!(classe, email, **atributos)
  classe.find_or_create_by!(email: email) do |u|
    u.assign_attributes(atributos)
    u.password = SENHA
  end
end

admin = usuario!(Admin, "admin@unilavras.edu.br", nome: "Administração da Clínica")

prof_ana = usuario!(Professor, "ana.supervisora@unilavras.edu.br",
                    nome: "Ana Paula Ribeiro", matricula: "P0001", telefone: "(35) 99999-0001")
prof_carlos = usuario!(Professor, "carlos.supervisor@unilavras.edu.br",
                       nome: "Carlos Eduardo Mendes", matricula: "P0002", telefone: "(35) 99999-0002")

maria = usuario!(Estagiario, "maria.estagiaria@unilavras.edu.br",
                 nome: "Maria Fernanda Souza", matricula: "E0001", supervisor: prof_ana)
pedro = usuario!(Estagiario, "pedro.estagiario@unilavras.edu.br",
                 nome: "Pedro Henrique Lima", matricula: "E0002", supervisor: prof_ana)
julia = usuario!(Estagiario, "julia.estagiaria@unilavras.edu.br",
                 nome: "Júlia Costa Almeida", matricula: "E0003", supervisor: prof_carlos)

# Consultas nos próximos dias úteis, só se ainda não houver nenhuma.
if Consulta.none?
  proximo_dia_util = Date.tomorrow
  proximo_dia_util += 1.day while proximo_dia_util.on_weekend?
  dia = proximo_dia_util.in_time_zone

  [
    [ maria, "João da Silva", "Sala 1", 9 ],
    [ maria, "Beatriz Oliveira", "Sala 1", 10 ],
    [ pedro, "Lucas Pereira", "Sala 2", 9 ],
    [ julia, "Camila Santos", "Sala 3", 14 ]
  ].each do |estagiario, paciente, sala, hora|
    inicio = dia.change(hour: hora)
    Consultas::Agendar.call(
      estagiario: estagiario,
      params: { paciente_nome: paciente, sala: sala, inicio: inicio, fim: inicio + 50.minutes,
                paciente_telefone: "(35) 98888-0000" }
    ).tap { |r| raise r.erros.join(", ") if r.falha? }
  end
end

puts "Seeds: #{Admin.count} admin, #{Professor.count} professores, " \
     "#{Estagiario.count} estagiários, #{Consulta.count} consultas. Senha de todos: #{SENHA}"
puts "Admin: #{admin.email}"
