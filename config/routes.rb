# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
  get "profile", to: "pages#profile", as: :profile

  namespace :api do
    namespace :v1 do
      resource :profile, only: [:show, :update]
      resources :countries, only: [:index] do
        resources :competitions, only: [:index] do
          resources :events, only: [:index, :show]
        end
      end
    end
  end

  resources :countries, only: [:index], param: :country_code do
    resources :competitions, only: [:index] do
      resources :events, only: [:index, :show]
    end
  end
end
