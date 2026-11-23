# Retorno padrão dos services: em vez de levantar exceção para erros de negócio,
# os services devolvem um Resultado que o chamador inspeciona.
#
#   resultado = Consultas::Agendar.call(...)
#   if resultado.sucesso? then resultado.valor else resultado.erros end
class Resultado
  attr_reader :valor, :erros, :codigo

  def self.sucesso(valor = nil)
    new(valor: valor)
  end

  # codigo: símbolo que identifica o tipo de falha (ex.: :conflito_horario),
  # útil para o frontend tratar casos específicos.
  def self.falha(erros, codigo: :invalido, valor: nil)
    new(valor: valor, erros: Array(erros), codigo: codigo)
  end

  def initialize(valor: nil, erros: [], codigo: nil)
    @valor = valor
    @erros = erros
    @codigo = codigo
  end

  def sucesso?
    erros.empty?
  end

  def falha?
    !sucesso?
  end
end
