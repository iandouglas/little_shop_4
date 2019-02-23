Rails.application.routes.draw do
  root 'welcome#index'

  resources :items, only: [:index, :show]

  resources :carts, only: [:create]

  resources :users, only: [:create, :update]

  resources :orders, only: :update

  get '/cart', to: 'carts#show'
  delete '/cart', to: 'carts#destroy'
  put '/cart', to: 'carts#update'
  get '/login', to: 'sessions#new'
  post '/login', to: 'sessions#create'
  get '/logout', to: 'sessions#destroy'
  get '/register', to: 'users#new'
  get '/merchants', to: 'users#index'

  scope :dashboard, module: :merchant, as: :dashboard do
    get '/', to: 'users#show'
    resources :items, only: [:index, :new, :edit, :update]
    resources :coupons, except: [:update]
    put '/coupons/:id/disable', to: 'coupons#disable', as: :disable_coupon
    put '/coupons/:id/enable', to: 'coupons#enab;e', as: :enable_coupon
  end

  namespace :merchant do
    resources :items, except: [:show, :index, :new, :edit, :update]

    put '/items/:id/enable', to: 'items#enable', as: :enable_item
    put '/items/:id/disable', to: 'items#disable', as: :disable_item
  end

  scope :profile, as: :profile do
    resources :orders, only: [:index, :show, :create]
    get '/', to: 'users#show'
    get '/edit', to: 'users#edit'
  end

  scope :dashboard, as: :merchant, module: :merchant do
    resources :orders, only: [:show, :update]
  end

  namespace :admin do
    resources :users, only: [:index, :show, :update, :edit]
    put '/users/:id/enable', to: 'users#enable', as: :enable_user
    put '/users/:id/disable', to: 'users#disable', as: :disable_user
    put 'users/:id/upgrade', to: 'users#upgrade', as: :upgrade_user
    put '/merchant/:id/downgrade', to: 'merchants#downgrade', as: :downgrade_merchant
    get '/dashboard', to: 'dashboard#show'
    resources :merchants, only: [:show, :update] do
      resources :items, except: :show
      put '/items/:id/enable', to: 'items#enable', as: :enable_item
      put '/items/:id/disable', to: 'items#disable', as: :disable_item
    end
    resources :orders, only: [:index, :show, :update]
  end
end
