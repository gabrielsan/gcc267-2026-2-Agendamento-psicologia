FactoryBot.define do
  factory :professor do
    sequence(:name) { |n| "Professor #{n}" }
    sequence(:email) { |n| "professor#{n}@unilavras.edu.br" }
    sequence(:crp) { |n| "04/#{10_000 + n}" }
    specialty { "Psicologia Clínica" }
    active { true }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
