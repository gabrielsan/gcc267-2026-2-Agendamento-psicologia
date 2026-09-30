Rails.application.routes.draw do
  devise_for :admins
  devise_for :estagiarios
  devise_for :professors, path: "professores"

  root "home#index"
  get "dashboard" => "dashboard#index", as: :dashboard

  resources :consultas
  resources :professores

  get "up" => "rails/health#show", as: :rails_health_check
end
