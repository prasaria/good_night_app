# config/routes.rb
Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1, constraints: ApiVersion::Constraint.new(1) do
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
      resources :followings, only: [ :index, :create, :destroy ]

      # Following sleep records route
      get "followings/sleep_records", to: "followings_sleep_records#index"
    end
  end

  get "api/v1/health", to: "api/v1/health#check"
end
