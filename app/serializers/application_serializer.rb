# Serializers simples (POROs): definem exatamente o JSON que a API devolve.
#
#   UsuarioSerializer.new(usuario).as_json
#   UsuarioSerializer.colecao(usuarios)
class ApplicationSerializer
  attr_reader :objeto

  def self.colecao(objetos)
    objetos.map { |objeto| new(objeto).as_json }
  end

  def initialize(objeto)
    @objeto = objeto
  end

  def as_json(*)
    raise NotImplementedError
  end
end
