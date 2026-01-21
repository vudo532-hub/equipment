Rails.application.routes.draw do
  devise_for :users

  # Dashboard
  root "pages#dashboard"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authenticated routes
  authenticate :user do
    # CUTE
    resources :cute_installations
    resources :cute_equipments

    # FIDS
    resources :fids_installations
    resources :fids_equipments

    # Audit logs
    resources :audit_logs, only: [:index, :show]

    # Export to Excel
    get "export/cute_equipments", to: "exports#cute_equipments", as: :export_cute_equipments
    get "export/fids_equipments", to: "exports#fids_equipments", as: :export_fids_equipments
    get "export/cute_installations", to: "exports#cute_installations", as: :export_cute_installations
    get "export/fids_installations", to: "exports#fids_installations", as: :export_fids_installations

    # API Tokens management
    resources :api_tokens, only: [:index, :create, :destroy]
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :cute_installations, only: [:index, :show, :create, :update, :destroy]
      resources :fids_installations, only: [:index, :show, :create, :update, :destroy]
      resources :cute_equipments, only: [:index, :show, :create, :update, :destroy]
      resources :fids_equipments, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
