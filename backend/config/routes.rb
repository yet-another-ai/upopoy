Rails.application.routes.draw do
  devise_for :users,
    path: "api/v1",
    only: :omniauth_callbacks,
    controllers: { omniauth_callbacks: "api/v1/users/omniauth_callbacks" }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        get "auth/providers", to: "users/auth_providers#index"
        post "auth/login", to: "users/sessions#create"
        delete "auth/logout", to: "users/sessions#destroy"
        post "auth/signup", to: "users/registrations#create"
        get "auth/me", to: "users/current_user#show"
      end

      resources :users, only: [ :index, :show, :update ]
      resources :groups

      resources :projects do
        member do
          get :board
        end

        resources :tasks, only: [ :index, :create ]
      end

      resources :tasks, only: [ :show, :update, :destroy ]
    end
  end
end
