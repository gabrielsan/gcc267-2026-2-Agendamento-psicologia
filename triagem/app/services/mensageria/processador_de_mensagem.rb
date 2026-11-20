module Mensageria
  # Transforma uma mensagem do broker numa decisão de confirmação:
  #
  #   :ack          processada (ou duplicada): pode confirmar
  #   :rejeitar     mensagem inválida ou que já falhou antes: vai para a DLQ
  #   :reenfileirar erro inesperado na primeira tentativa: tenta mais uma vez
  #
  # Fica separado do Consumidor para ser testado sem broker.
  class ProcessadorDeMensagem
    def initialize(roteador: Roteador.new, logger: Rails.logger)
      @roteador = roteador
      @logger = logger
    end

    def call(corpo, redelivered: false)
      envelope = Envelope.parse(corpo)
      resultado = @roteador.call(envelope)
      @logger.info("[triagem] #{envelope.event_type} consulta=#{envelope.consulta_id} " \
                   "event_id=#{envelope.event_id} => #{resultado}")
      :ack
    rescue EnvelopeInvalido => e
      @logger.error("[triagem] mensagem inválida, enviada para a DLQ: #{e.message}")
      :rejeitar
    rescue StandardError => e
      @logger.error("[triagem] erro inesperado: #{e.class}: #{e.message}")
      redelivered ? :rejeitar : :reenfileirar
    end
  end
end
