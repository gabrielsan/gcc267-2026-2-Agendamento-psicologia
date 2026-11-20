module Mensageria
  # Exchange, filas e bindings usados pela triagem.
  #
  #   psiline.events (topic) ──consulta.reserva_criada────▶ triagem.eventos ──(falha)──▶ psiline.events.dlx ▶ triagem.eventos.dlq
  #                          ──consulta.reserva_confirmada▶
  #                          ──consulta.reserva_cancelada─▶
  #
  # A triagem publica triagem.aprovada / triagem.reprovada na mesma exchange;
  # quem consome (agendamento, read model) declara a própria fila e faz o binding.
  class Topologia
    BINDINGS_DA_TRIAGEM = %w[
      consulta.reserva_criada
      consulta.reserva_confirmada
      consulta.reserva_cancelada
    ].freeze

    def self.exchange(canal)
      canal.topic(Config.exchange, durable: true)
    end

    # Declaração idempotente. Se a Parte 2 já criou a fila com argumentos
    # diferentes o RabbitMQ responde PRECONDITION_FAILED: nesse caso use
    # DECLARE_TOPOLOGY=false.
    def self.declarar(canal)
      exchange = exchange(canal)
      dlx = canal.fanout(Config.dlx, durable: true)
      canal.queue(Config.dlq, durable: true).bind(dlx)

      fila = canal.queue(Config.fila, durable: true, arguments: { "x-dead-letter-exchange" => Config.dlx })
      BINDINGS_DA_TRIAGEM.each { |chave| fila.bind(exchange, routing_key: chave) }
      [ exchange, fila ]
    end
  end
end
