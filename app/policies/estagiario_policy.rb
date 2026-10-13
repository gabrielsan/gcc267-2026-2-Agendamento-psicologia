# O admin gerencia estagiários. O professor vê os estagiários que supervisiona
# e o estagiário vê o próprio cadastro.
class EstagiarioPolicy < ApplicationPolicy
  def index? = admin? || professor?
  def show? = admin? || supervisiona? || record == usuario
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  private

  def supervisiona?
    professor? && record.supervisor_id == usuario.id
  end

  class Scope < Scope
    def resolve
      if usuario.admin?
        scope.all
      elsif usuario.professor?
        scope.where(supervisor_id: usuario.id)
      else
        scope.where(id: usuario.id)
      end
    end
  end
end
