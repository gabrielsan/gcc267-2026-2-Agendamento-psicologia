class ProfessoresController < AreaRestritaController
  before_action :carregar_professor, only: %i[show edit update destroy]

  def index
    authorize Professor
    professores = policy_scope(Professor).order(:nome, :id)
    professores = professores.busca(params[:busca]) if params[:busca].present?
    professores = professores.where(ativo: params[:ativo] == "true") if params[:ativo].in?(%w[true false])
    @professores = paginar(professores)
  end

  def show
    authorize @professor
  end

  def new
    authorize Professor
    @professor = Professor.new(ativo: true)
  end

  def create
    authorize Professor
    @professor = Professor.new(professor_params)
    if @professor.save
      redirect_to professor_path(@professor), notice: "Professor cadastrado com sucesso.", status: :see_other
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @professor
  end

  def update
    authorize @professor
    if @professor.update(professor_params)
      redirect_to professor_path(@professor), notice: "Professor atualizado com sucesso.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @professor
    if @professor.destroy
      redirect_to professores_path, notice: "Professor excluído com sucesso.", status: :see_other
    else
      @erros = @professor.errors.full_messages + ["Você pode desativar o cadastro para preservar os vínculos."]
      render :show, status: :unprocessable_content
    end
  end

  private

  def carregar_professor = @professor = Professor.find(params[:id])

  def professor_params
    dados = params.require(:professor).permit(:nome, :email, :password, :matricula, :telefone, :ativo)
    dados.delete(:password) if @professor&.persisted? && dados[:password].blank?
    dados[:matricula] = nil if dados.key?(:matricula) && dados[:matricula].blank?
    dados
  end
end
