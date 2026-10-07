class UsuarioSerializer < ApplicationSerializer
  def as_json(*)
    dados = {
      id: objeto.id,
      tipo: objeto.papel,
      nome: objeto.nome,
      email: objeto.email,
      matricula: objeto.matricula,
      telefone: objeto.telefone,
      ativo: objeto.ativo,
      criado_em: objeto.created_at,
      atualizado_em: objeto.updated_at
    }

    if objeto.estagiario?
      dados[:supervisor] = objeto.supervisor && { id: objeto.supervisor.id, nome: objeto.supervisor.nome }
    end

    dados
  end
end
