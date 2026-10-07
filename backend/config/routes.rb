Rails.application.routes.draw do
  # Health check (usado por Docker/CI/load balancer)
  get "up" => "rails/health#show", as: :rails_health_check

  # Registra o modelo no Devise/devise-jwt. As rotas de login/logout são as
  # definidas abaixo, não as padrão do Devise.
  devise_for :usuarios, skip: :all

  namespace :api do
    namespace :v1 do
      post "login", to: "sessoes#create"
      delete "logout", to: "sessoes#destroy"
      get "me", to: "me#show"

      resources :professores, except: %i[new edit]
      resources :estagiarios, except: %i[new edit]
      resources :consultas, except: %i[new edit] do
        get :disponibilidade, on: :collection
      end
    end
  end
end
