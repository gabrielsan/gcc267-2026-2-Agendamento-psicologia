module Consultas
  module Saga
    # Consome a fila psiline.agendamento (triagem.aprovada/triagem.reprovada,
    # ver docs/infraestrutura-mensageria.md) e aplica ProcessarResultadoTriagem
    # a cada mensagem.
    #
    # Política de retentativa simples: na primeira falha, a mensagem volta
    # para a fila (requeue); se falhar de novo (redelivered), vai para a
    # dead-letter psiline.agendamento.dead. Não há loop de requeue automático.
    class Consumidor
      FILA = "psiline.agendamento"

      def run
        @parando = false
        instalar_sinais
        conectar
        iniciar_heartbeat
        @consumidor = @fila.subscribe(manual_ack: true, block: false) { |info, _props, corpo| tratar(info, corpo) }
        sleep 1 until @parando
        @consumidor.cancel
      ensure
        @heartbeat&.kill
        desconectar
      end

      private

      def tratar(info, corpo)
        envelope = JSON.parse(corpo)
        resultado = ProcessarResultadoTriagem.call(envelope)
        Rails.logger.info("[saga] #{envelope['event_type']} consulta=#{envelope['consulta_id']} => #{resultado}")
        @canal.ack(info.delivery_tag)
      rescue StandardError => erro
        Rails.logger.error("[saga] falha ao processar mensagem: #{erro.class}: #{erro.message}")
        @canal.nack(info.delivery_tag, false, !info.redelivered)
      end

      def conectar
        @conexao = Bunny.new(ENV.fetch("RABBITMQ_URL"),
          automatically_recover: true, connection_timeout: 5,
          read_timeout: 5, write_timeout: 5, heartbeat: 10, logger: Rails.logger)
        @conexao.start
        @canal = @conexao.create_channel
        @canal.prefetch(10)
        Messaging::Topology.declare(@canal)
        @fila = @canal.queue(FILA, durable: true, arguments: {
          "x-dead-letter-exchange" => Messaging::Topology::DEAD_EXCHANGE,
          "x-dead-letter-routing-key" => FILA
        })
      end

      def desconectar
        @conexao.close if @conexao&.open?
      end

      def instalar_sinais
        %w[TERM INT].each { |sinal| Signal.trap(sinal) { @parando = true } }
      end

      def iniciar_heartbeat
        caminho = Rails.root.join("tmp/saga-heartbeat")
        FileUtils.mkdir_p(caminho.dirname)
        @heartbeat = Thread.new do
          until @parando
            FileUtils.touch(caminho)
            sleep 10
          end
        end
      end
    end
  end
end
