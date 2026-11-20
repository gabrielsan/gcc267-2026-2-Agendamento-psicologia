# Substitutos simples do exchange/canal do Bunny para testar o publicador sem broker.
class ExchangeFalso
  attr_reader :publicadas

  def initialize
    @publicadas = []
  end

  def publish(corpo, **opcoes)
    @publicadas << { corpo: corpo, opcoes: opcoes }
  end
end

class CanalFalso
  def initialize(confirma: true)
    @confirma = confirma
  end

  def wait_for_confirms
    @confirma
  end
end
