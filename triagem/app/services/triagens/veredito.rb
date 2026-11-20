module Triagens
  # Resultado de uma triagem: aprovada, ou reprovada com código e detalhe.
  class Veredito
    attr_reader :status, :codigo, :detalhe

    def self.aprovado
      new("aprovada")
    end

    def self.reprovado(codigo, detalhe)
      new("reprovada", codigo, detalhe)
    end

    def initialize(status, codigo = nil, detalhe = nil)
      @status = status
      @codigo = codigo
      @detalhe = detalhe
    end

    def aprovada?
      status == "aprovada"
    end
  end
end
