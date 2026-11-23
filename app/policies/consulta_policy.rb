# - Admin: vê, edita e exclui qualquer consulta.
# - Professor: vê e edita as consultas que supervisiona.
# - Estagiário: cria consultas, vê as próprias e edita as próprias em aberto
#   (agendada/confirmada). Não exclui: cancela mudando o status.
#
# O que cada papel pode alterar dentro da consulta fica em Consultas::Atualizar.
class ConsultaPolicy < ApplicationPolicy
  def index? = usuario.present?
  def show? = admin? || supervisiona? || propria?
  def create? = estagiario?
  def update? = admin? || supervisiona? || (propria? && record.em_aberto?)
  def destroy? = admin?

  # Horários livres não expõem dados de pacientes: qualquer usuário logado consulta.
  def disponibilidade? = usuario.present?

  private

  def supervisiona?
    professor? && record.professor_id == usuario.id
  end

  def propria?
    estagiario? && record.estagiario_id == usuario.id
  end

  class Scope < Scope
    def resolve
      if usuario.admin?
        scope.all
      elsif usuario.professor?
        scope.where(professor_id: usuario.id)
      else
        scope.where(estagiario_id: usuario.id)
      end
    end
  end
end
