# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"
  get "profile", to: "pages#profile", as: :profile

  namespace :api do
    namespace :v1 do
      resource :profile, only: [:show, :update]
      resources :countries, only: [:index] do
        resources :competitions, only: [:index] do
          resources :events, only: [:index, :show] do
            member do
              get :predictions
            end
          end
        end
      end
    end
  end

  ###

  resources :countries, only: [:index, :show] do
    resources :leagues, only: [:show]
  end

  resources :fixtures, only: [:show]
end
