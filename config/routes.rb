Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  # Dashboard
  root "pages#dashboard"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authenticated routes
  authenticate :user do
    # User profile
    resource :profile, only: [:show, :edit, :update], controller: 'profiles'

    # CUTE
    resources :cute_installations do
      member do
        post :search_equipment
        post :attach_equipment
        delete :detach_equipment
      end
    end
    resources :cute_equipments do
      collection do
        post :check_duplicate
      end
      member do
        post :assign_to_installation
        post :unassign_from_installation
        get :audit_history
      end
    end

    # FIDS
    resources :fids_installations do
      member do
        post :search_equipment
        post :attach_equipment
        delete :detach_equipment
      end
    end
    resources :fids_equipments do
      member do
        get :audit_history
      end
    end

    # ZAMAR
    resources :zamar_installations do
      member do
        post :search_equipment
        post :attach_equipment
        delete :detach_equipment
      end
    end
    resources :zamar_equipments do
      member do
        get :audit_history
      end
    end

    # Audit logs
    resources :audit_logs, only: [:index, :show]

    # Акты ремонта
    namespace :repairs do
      resources :acts, only: [:index, :show] do
        member do
          get :export_to_excel
        end
      end
    end

    # Ремонт
    resources :repairs, only: [:index, :show] do
      collection do
        post :create_batch
        get :history
      end
      member do
        patch :update_ticket_number
        get :export_to_excel
      end
    end

    # Export to Excel
    get "export/cute_equipments", to: "exports#cute_equipments", as: :export_cute_equipments
    get "export/fids_equipments", to: "exports#fids_equipments", as: :export_fids_equipments
    get "export/cute_installations", to: "exports#cute_installations", as: :export_cute_installations
    get "export/fids_installations", to: "exports#fids_installations", as: :export_fids_installations
    get "export/zamar_equipments", to: "exports#zamar_equipments", as: :export_zamar_equipments
    get "export/zamar_installations", to: "exports#zamar_installations", as: :export_zamar_installations

    # API Tokens management
    resources :api_tokens, only: [:index, :create, :destroy]

    # Admin routes
    namespace :admin do
      resources :users, only: [:index, :edit, :update]
    end
  end

  # API routes
  namespace :api do
    namespace :v1 do
      resources :cute_installations, only: [:index, :show, :create, :update, :destroy]
      resources :fids_installations, only: [:index, :show, :create, :update, :destroy]
      resources :zamar_installations, only: [:index, :show, :create, :update, :destroy]
      resources :cute_equipments, only: [:index, :show, :create, :update, :destroy]
      resources :fids_equipments, only: [:index, :show, :create, :update, :destroy]
      resources :zamar_equipments, only: [:index, :show, :create, :update, :destroy]
    end
  end
end
