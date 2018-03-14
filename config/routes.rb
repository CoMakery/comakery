require 'sidekiq/web'

Rails.application.routes.draw do
  resource :account, only: [:update]
  resource :authentication, only: [:show]
  resources :accounts, only: [:new, :create, :show]
  resources :password_resets, only: [:new, :create, :edit, :update]

  get '/account' => "accounts#show"
  get "accounts/confirm/:token" => "accounts#confirm", as: :confirm_email
  get "/auth/slack/callback" => "sessions#create"
  get "/auth/slack" => "sessions#create", as: :login

  get "/auth/discord/callback" => "sessions#create"
  get "/auth/discord" => "sessions#create", as: :login_discord

  get '/logout', to: "sessions#destroy"

  root 'projects#landing'

  resources :beta_signups, only: [:new, :create]

  resource :session, only: %i[new create destroy] do
    get "oauth_failure"
    collection do
      post :sign_in
    end
  end
  get '/session' => "sessions#create"

  post '/slack/command' => "slack#command"

  resources :projects do
    resources :awards, only: [:index, :create]
    resources :licenses, only: [:index]
    resources :contributors, only: [:index]
    resources :revenues, only: [:index, :create]
    resources :payments, only: [:index, :create, :update]
    collection do
      get :landing
    end
  end

  resources :teams, only: [:index] do
    member do
      get :channels
    end
  end

  resources :channes, only: [] do
    member do
      get :users
    end
  end

  unless Rails.env.development? || Rails.env.test?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username.present? && password.present? &&
        username == ENV["SIDEKIQ_USERNAME"] && password == ENV["SIDEKIQ_PASSWORD"]
    end
  end
  mount Sidekiq::Web, at: "/admin/sidekiq"
end
