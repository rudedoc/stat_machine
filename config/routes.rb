# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"

  namespace :api do
    namespace :v1 do
      resources :countries, only: [:index] do
        resources :competitions, only: [:index] do
          resources :matches, only: [:index]
        end
      end
    end
  end
end
