Rails.application.routes.draw do
  mount PgHero::Engine, at: "pghero"
  mount Rswag::Api::Engine, at: "api-docs"
  mount Rswag::Ui::Engine, at: "api-docs"

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
        get "auth/settings", to: "auth_settings#show"
        get "auth/providers", to: "users/auth_providers#index"
        post "auth/login", to: "users/sessions#create"
        delete "auth/logout", to: "users/sessions#destroy"
        post "auth/signup", to: "users/registrations#create"
        get "auth/me", to: "users/current_user#show"
      end

      namespace :admin do
        resource :settings, only: [ :show, :update ]
      end

      resources :users, only: [ :index, :show, :update ]
      resources :groups, only: [ :index, :show, :create, :update, :destroy ]
      get "search", to: "search#index"

      resources :projects, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          get :board
        end

        resources :iterations, only: [ :index, :create ]
        resources :tasks, only: [ :index, :create ]
        resources :drive_items, only: [ :index, :create ]
      end

      resources :iterations, only: [ :show, :update, :destroy ]
      resources :tasks, only: [ :show, :update, :destroy ]
      resources :drive_items, only: [ :show, :update, :destroy ] do
        member do
          get :content
          patch :content, action: :update_content
          get :download
          patch :file, action: :update_file
          get :versions
        end
      end

      resources :drive_item_versions, only: [] do
        member do
          get :content
          get :download
          post :restore
        end
      end
    end
  end
end
