FactoryBot.define do
  factory :consulta do
    association :estagiario
    association :professor
    patient_name { "Maria Silva" }
    patient_email { "maria@example.com" }
    patient_phone { "(35) 98888-0000" }
    starts_at { 2.days.from_now.change(hour: 10, min: 0, sec: 0) }
    ends_at { starts_at + 50.minutes }
    status { :solicitada }
    modality { :presencial }
    room { "Sala 3" }
    notes { "Primeira consulta" }
    supervision_notes { "Acompanhar evolução inicial" }
  end
end
