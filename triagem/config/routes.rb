Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Consulta de apoio/demonstração: resultado da triagem e estado da SAGA.
  namespace :api do
    namespace :v1 do
      resources :triagens, only: :show, param: :consulta_id
    end
  end
end
