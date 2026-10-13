Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :usuarios, only: :sessions, path: "",
    path_names: { sign_in: "entrar", sign_out: "sair" },
    controllers: { sessions: "usuarios/sessions" }

  root "home#index"
  get "painel", to: "painel#index"
  resources :consultas
  resources :professores

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
