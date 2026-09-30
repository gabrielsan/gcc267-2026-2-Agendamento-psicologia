class ConsultasController < ApplicationController
  before_action :authenticate_actor!
  before_action :require_estagiario!, only: %i[new create edit update]
  before_action :set_consulta, only: %i[show edit update destroy]
  before_action :require_admin!, only: %i[destroy]

  def index
    @consultas = consulta_scope.includes(:estagiario, :professor).chronological
  end

  def show; end

  def new
    @consulta = current_estagiario.consultas.build(default_consulta_attributes)
    load_professores
  end

  def edit
    return redirect_to consultas_path, alert: "Você só pode editar suas próprias consultas." unless owns_consulta?

    load_professores
  end

  def create
    result = Consultas::CreateService.new(estagiario: current_estagiario, params: consulta_params).call
    @consulta = result.record

    if result.success?
      redirect_to @consulta, notice: "Consulta agendada com sucesso."
    else
      load_professores
      render :new, status: :unprocessable_entity
    end
  end

  def update
    result = Consultas::UpdateService.new(consulta: @consulta, actor: current_actor, params: consulta_params).call
    @consulta = result.record

    if result.success?
      redirect_to @consulta, notice: "Consulta atualizada com sucesso."
    else
      load_professores
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Consultas::DestroyService.new(consulta: @consulta, actor: current_actor).call

    if result.success?
      redirect_to consultas_path, notice: "Consulta excluída com sucesso."
    else
      redirect_to @consulta, alert: result.record.errors.full_messages.to_sentence
    end
  end

  private

  def consulta_scope
    return Consulta.all if admin_actor?
    return current_estagiario.consultas if estagiario_actor?
    return current_professor.consultas if professor_actor?

    Consulta.none
  end

  def set_consulta
    @consulta = consulta_scope.find(params[:id])
  end

  def owns_consulta?
    @consulta.estagiario_id == current_estagiario.id
  end

  def load_professores
    @professores = Professor.active.ordered
  end

  def default_consulta_attributes
    starts_at = (Time.zone.now + 1.hour).change(min: 0, sec: 0)
    { starts_at:, ends_at: starts_at + 50.minutes, status: :solicitada, modality: :presencial }
  end

  def consulta_params
    params.require(:consulta).permit(:professor_id, :patient_name, :patient_email, :patient_phone, :starts_at, :ends_at, :status, :modality, :room, :notes, :supervision_notes)
  end
end
