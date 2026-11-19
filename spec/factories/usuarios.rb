FactoryBot.define do
  factory :admin do
    nome { "Admin #{Faker::Name.first_name}" }
    sequence(:email) { |n| "admin#{n}@unilavras.edu.br" }
    password { "senha123" }
  end

  factory :professor do
    nome { Faker::Name.name }
    sequence(:email) { |n| "professor#{n}@unilavras.edu.br" }
    sequence(:matricula) { |n| "P#{n.to_s.rjust(4, '0')}" }
    password { "senha123" }
  end

  factory :estagiario do
    nome { Faker::Name.name }
    sequence(:email) { |n| "estagiario#{n}@unilavras.edu.br" }
    sequence(:matricula) { |n| "E#{n.to_s.rjust(4, '0')}" }
    password { "senha123" }
    supervisor factory: :professor
  end
end
