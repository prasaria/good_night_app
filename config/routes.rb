# config/routes.rb
Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Sleep records routes
      resources :sleep_records, only: [ :index ] do
        collection do
          post "start", to: "sleep_records#start"
        end
        member do
          patch "end", to: "sleep_records#end"
        end
      end

      # Followings routes
      resources :followings, only: [ :index, :create, :destroy ] do
        collection do
          delete :destroy  # Add this line to support DELETE without ID
        end
      end

      # Following sleep records route
      get "followings/sleep_records", to: "followings_sleep_records#index"
    end
  end

  get "health", to: "api/v1/health#check"
  get "health/redis", to: "api/v1/health#redis"
end
