module Mensageria
  class Conexao
    # Abre a conexão com o RabbitMQ, tentando de novo enquanto o broker sobe.
    def self.abrir(tentativas: 30, espera: 2)
      tentativa = 0
      begin
        tentativa += 1
        Bunny.new(Config.url, automatically_recover: true, connection_name: "triagem").tap(&:start)
      rescue Bunny::Exception, SystemCallError => e
        raise if tentativa >= tentativas

        Rails.logger.warn("[mensageria] broker indisponível (#{e.class}); tentativa #{tentativa}/#{tentativas}")
        sleep espera
        retry
      end
    end
  end
end
