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
        resource :profile, only: [:show, :update], controller: "profiles"
      end

      namespace :employers do
        resource :profile, only: [:show, :update], controller: "profiles"
      end

      resources :jobs, only: [:index, :show, :create, :update] do
        resources :applications, only: :create
        get "applications", to: "applications#for_job"
      end

      resources :applications, only: [:index, :update]
    end
  end
end
