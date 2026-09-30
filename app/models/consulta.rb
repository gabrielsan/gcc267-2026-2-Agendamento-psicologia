class Consulta < ApplicationRecord
  belongs_to :estagiario
  belongs_to :professor

  enum status: { solicitada: 0, confirmada: 1, realizada: 2, cancelada: 3 }
  enum modality: { presencial: 0, online: 1 }

  validates :patient_name, :starts_at, :ends_at, :status, :modality, presence: true
  validates :room, presence: true, if: :presencial?
  validate :ends_after_starts_at
  validate :duration_is_reasonable
  validate :professor_must_be_active
  validate :estagiario_without_conflict
  validate :professor_without_conflict

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :chronological, -> { order(:starts_at) }
  scope :active_for_schedule, -> { where.not(status: :cancelada) }

  private

  def ends_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "deve ser depois do início") if ends_at <= starts_at
  end

  def duration_is_reasonable
    return if starts_at.blank? || ends_at.blank? || ends_at <= starts_at

    minutes = ((ends_at - starts_at) / 60).to_i
    errors.add(:ends_at, "deve gerar uma consulta entre 30 e 120 minutos") unless minutes.between?(30, 120)
  end

  def professor_must_be_active
    return if professor.blank? || professor.active?

    errors.add(:professor, "precisa estar ativo")
  end

  def estagiario_without_conflict
    return if estagiario_id.blank? || starts_at.blank? || ends_at.blank? || cancelada?

    conflict = Consulta.active_for_schedule
                       .where(estagiario_id:)
                       .where.not(id:)
                       .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                       .exists?
    errors.add(:base, "Estagiário já possui consulta neste horário") if conflict
  end

  def professor_without_conflict
    return if professor_id.blank? || starts_at.blank? || ends_at.blank? || cancelada?

    conflict = Consulta.active_for_schedule
                       .where(professor_id:)
                       .where.not(id:)
                       .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                       .exists?
    errors.add(:base, "Professor já possui supervisão neste horário") if conflict
  end
end
