require 'sidekiq/web'

Rails.application.routes.draw do

  namespace :admin do
    mount Sidekiq::Web => '/sidekiq'#, constraints: AdminRequiredConstraint.new
    get '/' => 'admin#index'
    resources :accounts
    get '/metrics' => 'metrics#index'
    resources :roles
  end

  get "/account" => "authentications#show", as: "account"
  resource :account, only: [:update]
  resource :authentication, only: [:show]

  get "/auth/slack/callback" => "sessions#create"
  get "/auth/slack" => "sessions#create", as: :login

  get '/logout', to: "sessions#destroy"

  root 'projects#landing'

  resources :beta_signups, only: [:new, :create]

  resource :session, only: %i[create destroy] do
    get "oauth_failure"
  end
  get '/session' => "sessions#create"

  post '/slack/command' => "slack#command"

  resources :projects do
    resources :awards, only: [:index, :create]
    collection do
      get :landing
    end
  end
end
