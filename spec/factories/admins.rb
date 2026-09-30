FactoryBot.define do
  factory :admin do
    sequence(:name) { |n| "Admin #{n}" }
    sequence(:email) { |n| "admin#{n}@unilavras.edu.br" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
