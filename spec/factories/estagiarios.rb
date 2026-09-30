FactoryBot.define do
  factory :estagiario do
    sequence(:name) { |n| "Estagiario #{n}" }
    sequence(:email) { |n| "estagiario#{n}@unilavras.edu.br" }
    sequence(:registration) { |n| "2026#{n.to_s.rjust(4, '0')}" }
    phone { "(35) 99999-0000" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
