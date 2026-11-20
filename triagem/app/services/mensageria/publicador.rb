module Mensageria
  # Publicador da outbox: lê eventos pendentes, envia ao broker com publisher
  # confirms e só então marca published_at. Garante "pelo menos uma vez":
  # se cair entre publicar e marcar, o evento sai de novo, e os consumidores
  # são idempotentes.
  class Publicador
    LOTE = 50

    def self.iniciar
      conexao = Conexao.abrir
      canal = conexao.create_channel
      canal.confirm_select
      Topologia.declarar(canal) if Config.declarar_topologia?
      new(canal: canal, exchange: Topologia.exchange(canal), conexao: conexao)
    end

    def initialize(canal:, exchange:, conexao: nil, logger: Rails.logger)
      @canal = canal
      @exchange = exchange
      @conexao = conexao
      @logger = logger
    end

    # Publica um lote de pendentes. Devolve quantos foram publicados.
    # FOR UPDATE SKIP LOCKED permite mais de um publicador sem pegar o mesmo evento.
    def publicar_pendentes
      OutboxEvent.transaction do
        lote = OutboxEvent.pendentes.order(:id).limit(LOTE).lock("FOR UPDATE SKIP LOCKED").to_a
        next 0 if lote.empty?

        lote.each { |evento| publicar(evento) }
        raise FalhaPublicacao, "o broker não confirmou o recebimento do lote" unless @canal.wait_for_confirms

        OutboxEvent.where(id: lote.map(&:id)).update_all(published_at: Time.current)
        @logger.info("[publicador] #{lote.size} evento(s) publicado(s)")
        lote.size
      end
    end

    def rodar(intervalo: 1.0)
      @executando = true
      %w[INT TERM].each { |sinal| Signal.trap(sinal) { @executando = false } }
      Rails.logger.info("[publicador] iniciado")

      while @executando
        publicados = publicar_com_protecao
        sleep(intervalo) if publicados.zero?
      end
      @conexao&.close
    end

    private

    def publicar(evento)
      @exchange.publish(
        evento.payload.to_json,
        routing_key: evento.event_type,
        persistent: true,
        message_id: evento.event_id,
        type: evento.event_type,
        content_type: "application/json"
      )
    end

    def publicar_com_protecao
      publicar_pendentes
    rescue StandardError => e
      @logger.error("[publicador] falha ao publicar: #{e.class}: #{e.message}")
      sleep 5
      0
    end
  end
end
