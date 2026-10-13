class ConsultaSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: objeto.id,
      status: objeto.status,
      inicio: objeto.inicio,
      fim: objeto.fim,
      duracao_minutos: objeto.duracao_em_minutos,
      sala: objeto.sala,
      paciente: {
        nome: objeto.paciente_nome,
        telefone: objeto.paciente_telefone,
        email: objeto.paciente_email
      },
      observacoes: objeto.observacoes,
      estagiario: resumo(objeto.estagiario),
      professor: resumo(objeto.professor),
      criado_em: objeto.created_at,
      atualizado_em: objeto.updated_at
    }
  end

  private

  def resumo(usuario)
    usuario && { id: usuario.id, nome: usuario.nome }
  end
end
