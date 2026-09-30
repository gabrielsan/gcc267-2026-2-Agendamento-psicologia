class ProfessoresController < ApplicationController
  before_action :authenticate_actor!
  before_action :require_admin!, except: %i[index show]
  before_action :set_professor, only: %i[show edit update destroy]

  def index
    @professores = Professor.ordered
  end

  def show; end

  def new
    @professor = Professor.new(active: true)
  end

  def edit; end

  def create
    @professor = Professor.new(professor_params)

    if @professor.save
      redirect_to @professor, notice: "Professor cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @professor.update(professor_params)
      redirect_to @professor, notice: "Professor atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @professor.destroy
      redirect_to professores_path, notice: "Professor excluído com sucesso."
    else
      redirect_to @professor, alert: @professor.errors.full_messages.to_sentence
    end
  end

  private

  def set_professor
    @professor = Professor.find(params[:id])
  end

  def professor_params
    params.require(:professor).permit(:name, :email, :crp, :specialty, :active, :password, :password_confirmation)
  end
end
