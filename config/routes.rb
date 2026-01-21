Rails.application.routes.draw do
  devise_for :users

  # Dashboard
  root "pages#dashboard"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authenticated routes
  authenticate :user do
    # Resources will be added later for CUTE and FIDS
  end
end
