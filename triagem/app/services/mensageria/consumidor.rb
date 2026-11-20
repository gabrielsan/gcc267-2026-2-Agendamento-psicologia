module Mensageria
  # Lê a fila da triagem e confirma (ack) a mensagem só depois que a transação
  # no banco terminou. Se o processo cair no meio, o broker reentrega, e a
  # idempotência (processed_events) impede efeito duplicado.
  class Consumidor
    PREFETCH = 10

    def initialize(conexao: Conexao.abrir, processador: ProcessadorDeMensagem.new)
      @conexao = conexao
      @processador = processador
    end

    def rodar
      canal = @conexao.create_channel
      canal.prefetch(PREFETCH)
      fila = if Config.declarar_topologia?
        Topologia.declarar(canal).last
      else
        canal.queue(Config.fila, passive: true)
      end

      %w[INT TERM].each { |sinal| Signal.trap(sinal) { Thread.new { @conexao.close } } }
      Rails.logger.info("[triagem] consumindo #{Config.fila}")

      fila.subscribe(manual_ack: true, block: true) do |info, _propriedades, corpo|
        acao = ActiveRecord::Base.connection_pool.with_connection do
          @processador.call(corpo, redelivered: info.redelivered?)
        end

        case acao
        when :ack then canal.acknowledge(info.delivery_tag)
        when :rejeitar then canal.reject(info.delivery_tag, false)
        when :reenfileirar then canal.reject(info.delivery_tag, true)
        end
      end
    end
  end
end
