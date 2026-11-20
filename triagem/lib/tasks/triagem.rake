namespace :triagem do
  desc "Consome eventos do broker (processo de longa duração)"
  task consumidor: :environment do
    $stdout.sync = true
    Mensageria::Consumidor.new.rodar
  end

  desc "Publica no broker os eventos pendentes da outbox (processo de longa duração)"
  task publicador: :environment do
    $stdout.sync = true
    Mensageria::Publicador.iniciar.rodar
  end

  desc "Simula o serviço de agendamento. Cenários: sucesso, sala_invalida, supervisor_invalido, conflito, duplicada, confirmar, cancelar"
  task :simular, [ :cenario, :consulta_id ] => :environment do |_tarefa, args|
    Mensageria::Simulador.new.executar(args[:cenario] || "sucesso", consulta_id: args[:consulta_id])
  end
end
