require 'sidekiq/web'

Rails.application.routes.draw do
  root 'projects#landing'

  resources :tokens, only: [:index, :new, :create, :show, :edit, :update] do
    collection do
      post :fetch_contract_details
    end
  end

  get '/styleguide' => "pages#styleguide"
  get '/unsubscription' => "unsubscription#new", as: :unsubscription

  resource :account, only: [:update]
  resources :wallets do
    member do
      get :algorand_opt_ins
      patch :make_primary
    end
  end
  resources :algorand_opt_ins, only: %i[index create]
  resources :accounts, only: [:index, :new, :create, :show] do
    collection do
      get :download_data
      get :build_profile
      patch :update_profile
    end
  end

  resources :password_resets, only: [:new, :create, :edit, :update]

  get '/account' => "accounts#show", as: :show_account
  get "accounts/confirm/:token" => "accounts#confirm", as: :confirm_email
  get "accounts/confirm-authentication/:token" => "accounts#confirm_authentication", as: :confirm_authentication
  get "/auth/slack/callback" => "sessions#create"
  post "/auth/slack" => "sessions#create", as: :login

  get "/auth/discord/callback" => "sessions#create"
  post "/auth/discord" => "sessions#create", as: :login_discord

  get '/logout', to: "sessions#destroy"

  get '/joinus' => "pages#join_us"
  get '/user-agreement' => "pages#user_agreement"
  get '/e-sign-disclosure' => "pages#e_sign_disclosure"
  get '/privacy-policy' => "pages#privacy_policy"
  get '/prohibited-use' => "pages#prohibited_use"
  get '/contribution_licenses/:type' => "pages#contribution_licenses", as: :contribution_licenses

  resource :session, only: %i[new create destroy] do
    get "oauth_failure"
    collection do
      post :sign_in
    end
  end
  get '/session' => "sessions#create"

  get '/tasks' => "awards#index", as: :my_tasks

  post '/slack/command' => "slack#command"

  get '/projects/mine' => "projects#landing", as: :my_project

  resources :projects do
    resources :invites, only: [:create], controller: 'projects/invites'
    resources :accounts do
      resources :permissions, only: %i[show update], controller: 'projects/accounts/permissions'
      resource :settings, only: [:show], controller: 'projects/accounts/settings'
    end

    resources :transfers do
      resource :settings, only: [:show], controller: 'projects/transfers/settings'
    end

    resources :award_types, path: 'batches', except: [:show] do
      resources :awards, path: 'tasks', except: [:index] do
        post :recipient_address
        post :send_award
        post :update_transaction_address
        get :clone
        get :award
        get :assignment
        post :assign
        post :start
        get :start
        post :submit
        post :accept
        post :reject
      end
    end
    resources :contributors, only: [:index]
    resources :project_roles, only: %i[create destroy], defaults: { format: :json }

    namespace :dashboard do
      resources :transfers, only: %i[index show edit update new create] do
        collection do
          get :fetch_chart_data
          post :export
        end
        member do
          patch :prioritize
        end
      end
      resources :accounts, only: [:index, :show, :create] do
        collection do
          post :refresh_from_blockchain
        end
        member do
          get :wallets
        end
      end
      resources :accesses, only: [:index] do
        collection do
          post :regenerate_api_key
        end
      end
      resources :reg_groups, only: [:create, :update, :destroy]

      get 'transfer_categories', to: 'transfer_types#index', as: :transfer_categories

      resources :transfer_types, only: [:create, :update, :destroy]
      resources :transfer_rules, only: [:create, :destroy, :index] do
        collection do
          post :freeze
          post :refresh_from_blockchain
        end
      end
    end

    collection do
      get :landing
      patch :update_status
    end
  end

  get '/p/:long_id' => "projects#unlisted", as: :unlisted_project
  get "awards/confirm/:token" => "awards#confirm", as: :confirm_award

  resources :teams, only: [:index] do
    member do
      get :channels
    end
  end

  resources :channels, only: [] do
    member do
      get :users
    end
  end

  resources :missions do
    collection do
      post :rearrange
    end
  end

  namespace :auth, defaults: { format: :json } do
    resources :eth, only: [:new, :create]

    post 'ore_id/new'
    delete 'ore_id/destroy'
    get 'ore_id/receive'
  end

  namespace :sign, defaults: { format: :json } do
    match 'ore_id/new', to: 'ore_id#new', via: [:get, :post]
    get 'ore_id/receive'

    match 'user_wallet/new', to: 'user_wallet#new', via: [:get, :post]
    get 'user_wallet/receive'
  end

  resources :invites, only: [:show] do
    member do
      get :redirect
    end
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :accounts, only: [:show, :update, :create] do
        resources :project_roles, only: %i[index create destroy]
        resources :verifications, only: [:index, :create]
        resources :wallets, only: [:index, :show, :create, :update, :destroy] do
          member do
            post :password_reset
          end
        end
        resources :transfers, only: [:index], controller: :account_transfers
        get :token_balances
      end

      resources :projects, only: [:show, :index] do
        resources :blockchain_transactions, only: [:create, :update, :destroy]
        resources :transfers, only: [:index, :show, :create, :destroy]
        resources :transfer_rules, only: [:index, :show, :create, :destroy]
        resources :reg_groups, only: [:index, :show, :create, :destroy]
        resources :hot_wallet_addresses, only: :create
      end

      resources :tokens, only: :index do
        resources :account_token_records, only: [:index, :create] do
          collection do
            delete :index, action: :destroy_all
          end
        end
        resources :wallet_transfer_rules, controller: 'account_token_records', only: [:index, :create] do
          collection do
            delete :index, action: :destroy_all
          end
        end
      end

      namespace :wallet_recovery do
        get :public_wrapping_key
        post :recover
      end
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
