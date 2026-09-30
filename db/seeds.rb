admin = Admin.find_or_initialize_by(email: "admin@unilavras.edu.br")
admin.update!(name: "Coordenação Unilavras", password: "password123", password_confirmation: "password123")

estagiario = Estagiario.find_or_initialize_by(email: "estagiario@unilavras.edu.br")
estagiario.update!(name: "Ana Estagiária", registration: "2026001", phone: "(35) 99999-0001", password: "password123", password_confirmation: "password123")

professores = [
  ["Dra. Helena Martins", "helena.martins@unilavras.edu.br", "04/12345", "Terapia Cognitivo-Comportamental"],
  ["Dr. Rafael Andrade", "rafael.andrade@unilavras.edu.br", "04/67890", "Psicologia Clínica"],
  ["Dra. Camila Rocha", "camila.rocha@unilavras.edu.br", "04/54321", "Avaliação Psicológica"]
]

professores.each do |name, email, crp, specialty|
  professor = Professor.find_or_initialize_by(email:)
  professor.update!(
    name:,
    crp:,
    specialty:,
    active: true,
    password: "password123",
    password_confirmation: "password123"
  )
end
