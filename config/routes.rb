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
  end
end
