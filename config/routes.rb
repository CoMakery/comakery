Rails.application.routes.draw do
  namespace :admin do
    get '/' => 'admin#index'
    resources :accounts
    get '/metrics' => 'metrics#index'
    resources :roles
  end

  get "/auth/:provider/callback" => "sessions#create"

  get '/home', to: "logged_out#show", as: :logged_out

  root 'projects#landing'

  get '/log_out', to: "sessions#destroy"
  get '/logout', to: "sessions#destroy"

  resource :session, only: %i[create destroy] do
    get "oauth_failure"
  end
  get '/session' => "sessions#create"

  post '/slack/command' => "slack#command"

  resources :projects do
    collection do
      get :landing
    end
    resources :rewards, only: [:index, :create]
  end
end
