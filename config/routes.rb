Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  get "philosophy" => "philosophy#show"
  
  # Admin routes - protected by authentication
  namespace :admin do
    root 'dashboard#index'
    resources :quotes do
      member do
        patch :toggle_status
      end
      collection do
        get :export
        post :bulk_action
      end
    end
    resources :users do
      member do
        patch :update_role
        patch :toggle_status
      end
      collection do
        get :export
        post :bulk_action
      end
    end
    resources :analytics, only: [:index]
    resources :activity_logs, only: [:index, :show]
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # This sets the home page to display the daily Tolkien quote via the QuotesController's index action.
  root "quotes#index"
end
