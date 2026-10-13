class ConsultasController < AreaRestritaController
  before_action :carregar_consulta, only: %i[show edit update destroy]

  def index
    consultas = policy_scope(Consulta).includes(:professor, :estagiario).order(:inicio, :id)
    consultas = consultas.do_dia(data_do_filtro) if params[:data].present?
    consultas = consultas.where(status: params[:status]) if params[:status].present?
    if params[:busca].present?
      consultas = consultas.where("paciente_nome ILIKE ?", "%#{Consulta.sanitize_sql_like(params[:busca].strip)}%")
    end
    @consultas = paginar(consultas)
  end

  def show
    authorize @consulta
  end

  def new
    authorize Consulta
    @consulta = current_usuario.consultas.build(status: :agendada)
  end

  def create
    authorize Consulta
    resultado = Consultas::Agendar.call(estagiario: current_usuario, params: consulta_params)
    @consulta = resultado.valor
    if resultado.sucesso?
      redirect_to consulta_path(@consulta), notice: "Consulta agendada com sucesso.", status: :see_other
    else
      @erros = resultado.erros
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @consulta
  end

  def update
    authorize @consulta
    resultado = Consultas::Atualizar.call(consulta: @consulta, params: consulta_params, usuario: current_usuario)
    if resultado.sucesso?
      redirect_to consulta_path(@consulta), notice: "Consulta atualizada com sucesso.", status: :see_other
    else
      @erros = resultado.erros
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @consulta
    @consulta.destroy!
    redirect_to consultas_path, notice: "Consulta excluída com sucesso.", status: :see_other
  end

  private

  def carregar_consulta = @consulta = Consulta.find(params[:id])

  def consulta_params
    params.require(:consulta).permit(:estagiario_id, :paciente_nome, :paciente_email,
      :paciente_telefone, :inicio, :fim, :sala, :status, :observacoes)
  end
end
