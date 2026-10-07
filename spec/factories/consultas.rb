FactoryBot.define do
  factory :consulta do
    estagiario
    paciente_nome { Faker::Name.name }
    paciente_telefone { "(35) 98888-0000" }
    sequence(:sala) { |n| "Sala #{n}" }
    inicio { 2.days.from_now.change(hour: 10, min: 0) }
    fim { inicio + 50.minutes }

    # Consulta que já aconteceu (ignora a validação de início no futuro).
    trait :passada do
      inicio { 2.days.ago.change(hour: 10, min: 0) }
      professor { estagiario.supervisor }
      to_create { |consulta| consulta.save!(validate: false) }
    end
  end
end
