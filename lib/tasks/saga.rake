namespace :saga do
  desc "Consome psiline.agendamento e confirma/compensa a reserva (SIGTERM/SIGINT para parar)"
  task consumir: :environment do
    Consultas::Saga::Consumidor.new.run
  end
end
