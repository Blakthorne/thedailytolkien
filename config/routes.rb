Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions: "users/sessions"
  }

  # User management routes
  patch "users/update_timezone", to: "users#update_timezone"

  get "philosophy" => "philosophy#show"

  # Admin routes - protected by authentication
  namespace :admin do
    root "dashboard#index"
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
        patch :reset_streak
        patch :recalculate_streak
        patch :update_streak
      end
      collection do
        get :export
        post :bulk_action
      end
    end
    resources :activity_logs, only: [ :index, :show ]
    resources :tags do
      member do
        post :add_to_quote
        delete :remove_from_quote
      end
    end
    resources :comments, only: [ :index, :destroy ]

    # Import/Export functionality
    get "import_export", to: "import_export#index"
    post "import_export/import", to: "import_export#import"
    get "import_export/export", to: "import_export#export"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Discover routes for browsing historical quotes
  resources :discover, only: [ :index, :show ], param: :id, constraints: {
    id: /\d+/  # Numeric ID validation
  }

  # Quote interaction routes
  resources :quotes, only: [] do
    resources :quote_likes, only: [ :create ], path: "likes", defaults: { format: :json }
    resources :comments, only: [ :index, :create ]
  end

  resources :comments, only: [ :update, :destroy ]

  # Defines the root path route ("/")
  # This sets the home page to display the daily Tolkien quote via the QuotesController's index action.
  root "quotes#index"

  # Catch-all route for unmatched URLs - must be last
  match "*unmatched", to: "application#render_404", via: :all
end
