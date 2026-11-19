# Base das policies (Pundit). Por padrão tudo é negado; cada policy libera
# explicitamente o que cada papel pode fazer.
class ApplicationPolicy
  attr_reader :usuario, :record

  def initialize(usuario, record)
    @usuario = usuario
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false

  private

  def admin? = usuario&.admin?
  def professor? = usuario&.professor?
  def estagiario? = usuario&.estagiario?

  class Scope
    def initialize(usuario, scope)
      @usuario = usuario
      @scope = scope
    end

    def resolve
      raise NoMethodError, "Defina #resolve em #{self.class}"
    end

    private

    attr_reader :usuario, :scope
  end
end
