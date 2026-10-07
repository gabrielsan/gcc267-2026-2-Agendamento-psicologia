class Consulta < ApplicationRecord
  DURACAO_MINIMA = 30.minutes
  DURACAO_MAXIMA = 2.hours

  # Status a partir dos quais cada status pode ser alcançado.
  # realizada, cancelada e falta são finais.
  TRANSICOES = {
    "agendada" => %w[confirmada cancelada realizada falta],
    "confirmada" => %w[agendada cancelada realizada falta],
    "realizada" => [],
    "cancelada" => [],
    "falta" => []
  }.freeze

  # Status que só fazem sentido depois do horário de início.
  STATUS_POS_ATENDIMENTO = %w[realizada falta].freeze

  belongs_to :estagiario, inverse_of: :consultas
  belongs_to :professor, inverse_of: :consultas_supervisionadas

  enum :status, {
    agendada: "agendada",
    confirmada: "confirmada",
    realizada: "realizada",
    cancelada: "cancelada",
    falta: "falta"
  }, default: :agendada, validate: true

  normalizes :sala, with: ->(sala) { sala.squish }
  normalizes :paciente_nome, with: ->(nome) { nome.squish }
  normalizes :paciente_email, with: ->(email) { email.strip.downcase }

  # O professor responsável é sempre o supervisor do estagiário.
  before_validation :definir_professor, if: -> { estagiario.present? && (professor_id.blank? || will_save_change_to_estagiario_id?) }

  validates :paciente_nome, presence: true, length: { maximum: 120 }
  validates :paciente_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :paciente_telefone, length: { maximum: 20 }, allow_blank: true
  validates :inicio, :fim, :sala, presence: true
  validates :sala, length: { maximum: 50 }
  validate :fim_depois_do_inicio
  validate :duracao_permitida
  validate :inicio_no_futuro, on: :create
  validate :transicao_de_status, on: :update, if: :will_save_change_to_status?
  validate :pos_atendimento_apos_inicio, if: :will_save_change_to_status?
  validate :professor_supervisiona_estagiario,
           if: -> { new_record? || will_save_change_to_professor_id? || will_save_change_to_estagiario_id? }

  scope :ativas, -> { where.not(status: :cancelada) }
  scope :em_aberto, -> { where(status: %i[agendada confirmada]) }
  scope :futuras, -> { where(inicio: Time.current..) }
  scope :sobrepostas, ->(inicio, fim) { where("consultas.inicio < ? AND consultas.fim > ?", fim, inicio) }
  scope :entre, ->(de, ate) { where(inicio: de..ate) }
  scope :do_dia, ->(data) { where(inicio: data.all_day) }

  # Estagiário só altera consultas que ainda não terminaram.
  def em_aberto?
    agendada? || confirmada?
  end

  def duracao_em_minutos
    return unless inicio && fim

    ((fim - inicio) / 60).round
  end

  def pode_mudar_para?(novo_status)
    TRANSICOES.fetch(status_was.to_s, []).include?(novo_status.to_s)
  end

  private

  def definir_professor
    self.professor = estagiario.supervisor
  end

  def fim_depois_do_inicio
    return unless inicio && fim

    errors.add(:fim, :depois_do_inicio) if fim <= inicio
  end

  def duracao_permitida
    return unless inicio && fim && fim > inicio

    duracao = fim - inicio
    return if duracao.between?(DURACAO_MINIMA, DURACAO_MAXIMA)

    errors.add(:base, :duracao_invalida,
               minimo: DURACAO_MINIMA.in_minutes.to_i, maximo: DURACAO_MAXIMA.in_minutes.to_i)
  end

  def inicio_no_futuro
    errors.add(:inicio, :no_passado) if inicio && inicio < Time.current
  end

  def transicao_de_status
    return if status_was.nil? || pode_mudar_para?(status)

    errors.add(:status, :transicao_invalida, de: status_was, para: status)
  end

  def pos_atendimento_apos_inicio
    return unless STATUS_POS_ATENDIMENTO.include?(status) && inicio && inicio > Time.current

    errors.add(:inicio, :antes_de_concluir, status: status)
  end

  def professor_supervisiona_estagiario
    return unless estagiario && professor_id

    errors.add(:professor, :nao_e_supervisor) if professor_id != estagiario.supervisor_id
  end
end
