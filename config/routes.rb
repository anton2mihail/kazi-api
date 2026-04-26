Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      resource :me, only: :show, controller: "me"

      namespace :auth do
        post "otp/start", to: "otp#start"
        post "otp/verify", to: "otp#verify"
        delete "logout", to: "sessions#destroy"
      end

      namespace :reference do
        get "trades", to: "/api/v1/reference#trades"
        get "locations", to: "/api/v1/reference#locations"
      end

      namespace :workers do
        resource :profile, only: [ :show, :update ], controller: "profiles"
        resources :candidates, only: :index
      end

      namespace :employers do
        resource :profile, only: [ :show, :update ], controller: "profiles"
      end

      resources :jobs, only: [ :index, :show, :create, :update ] do
        member do
          patch "repost"
          patch "archive"
        end

        resources :applications, only: :create
        get "applications", to: "applications#for_job"
      end

      resources :applications, only: [ :index, :update ]
      resources :interview_requests, only: [ :index, :create ] do
        member do
          patch "respond"
          patch "cancel"
        end
      end

      resources :work_history, only: [ :index, :create ], controller: "work_history" do
        member do
          patch "confirm"
          patch "dispute"
          post "review"
        end
      end

      namespace :reports do
        post "jobs", to: "/api/v1/reports#create_job"
        post "users", to: "/api/v1/reports#create_user"
      end

      resources :notifications, only: [ :index ] do
        member do
          patch "read"
        end

        collection do
          patch "read_all"
        end
      end

      resource :notification_preferences, only: [ :show, :update ]

      namespace :admin do
        resources :employer_verifications, only: :index do
          member do
            patch "approve"
            patch "reject"
            patch "request_more_info"
          end
        end

        resources :employers, only: [] do
          member do
            patch "suspend"
            patch "unsuspend"
          end
        end

        resources :invite_codes, only: [ :index, :create, :update ]
        resources :reports, only: [ :index, :update ]
      end
    end
  end
end
