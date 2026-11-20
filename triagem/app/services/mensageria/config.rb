module Mensageria
  # Nomes do broker. Tudo pode ser trocado por variável de ambiente, para
  # alinhar com a infraestrutura definida na Parte 2 sem mexer no código.
  module Config
    module_function

    def url
      ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672")
    end

    def exchange
      ENV.fetch("EVENTS_EXCHANGE", "psiline.events")
    end

    def dlx
      ENV.fetch("EVENTS_DLX", "psiline.events.dlx")
    end

    def fila
      ENV.fetch("TRIAGEM_QUEUE", "triagem.eventos")
    end

    def dlq
      ENV.fetch("TRIAGEM_DLQ", "triagem.eventos.dlq")
    end

    # Se false, o serviço assume que a Parte 2 já criou exchanges/filas/bindings.
    def declarar_topologia?
      ENV.fetch("DECLARE_TOPOLOGY", "true") == "true"
    end
  end
end
