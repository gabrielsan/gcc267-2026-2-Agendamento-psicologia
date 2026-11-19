module Messaging
  module Topology
    EXCHANGE = "psiline.events"
    DEAD_EXCHANGE = "psiline.dead"
    BINDINGS = {
      "psiline.triagem" => %w[consulta.reserva_criada],
      "psiline.agendamento" => %w[triagem.aprovada triagem.reprovada],
      "psiline.read_model" => OutboxEvent::TYPES
    }.freeze

    def self.declare(channel)
      exchange = channel.topic(EXCHANGE, durable: true)
      dead = channel.topic(DEAD_EXCHANGE, durable: true)
      BINDINGS.each do |name, keys|
        channel.queue("#{name}.dead", durable: true).bind(dead, routing_key: name)
        queue = channel.queue(name, durable: true, arguments: {
          "x-dead-letter-exchange" => DEAD_EXCHANGE, "x-dead-letter-routing-key" => name
        })
        keys.each { |key| queue.bind(exchange, routing_key: key) }
      end
      exchange
    end
  end
end
