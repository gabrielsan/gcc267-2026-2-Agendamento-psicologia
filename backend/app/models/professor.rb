# Professor supervisor: acompanha os estagiários e as consultas deles.
class Professor < Usuario
  has_many :estagiarios, foreign_key: :supervisor_id, inverse_of: :supervisor,
           dependent: :restrict_with_error
  has_many :consultas_supervisionadas, class_name: "Consulta", foreign_key: :professor_id,
           inverse_of: :professor, dependent: :restrict_with_error

  def professor? = true
end
