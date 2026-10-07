# Somente o admin gerencia professores. O professor pode ver o próprio cadastro.
class ProfessorPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin? || record == usuario
  def create? = admin?
  def update? = admin?
  def destroy? = admin?

  class Scope < Scope
    def resolve
      if usuario.admin?
        scope.all
      elsif usuario.professor?
        scope.where(id: usuario.id)
      else
        scope.none
      end
    end
  end
end
