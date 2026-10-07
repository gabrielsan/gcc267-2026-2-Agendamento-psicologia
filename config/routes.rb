Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions.
  get "up" => "rails/health#show", as: :rails_health_check

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

  # Root route to be defined by the team.
  # root "home#index"
end
