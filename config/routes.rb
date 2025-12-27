# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
  get "stats", to: "pages#stats", as: :stats
  get "profile", to: "pages#profile", as: :profile

  namespace :api do
    namespace :v1 do
      resource :profile, only: [:show, :update]
      resources :countries, only: [:index] do
        resources :competitions, only: [:index] do
          resources :matches, only: [:index]
        end
      end
    end
  end
end
