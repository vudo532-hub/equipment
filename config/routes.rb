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

    # Export
    get "export/cute_equipments", to: "exports#cute_equipments", as: :export_cute_equipments
    get "export/fids_equipments", to: "exports#fids_equipments", as: :export_fids_equipments
  end
end
