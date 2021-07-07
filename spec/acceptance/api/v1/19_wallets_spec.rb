require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'IX. Wallets' do
  include Rails.application.routes.url_helpers

  before do
    Timecop.freeze(Time.zone.local(2021, 4, 6, 10, 5, 0))
    allow_any_instance_of(Comakery::APISignature).to receive(:nonce).and_return('0242d70898bcf3fbb5fa334d1d87804f')
  end

  after do
    Timecop.return
  end

  let!(:active_whitelabel_mission) { create(:mission, whitelabel: true, whitelabel_domain: 'example.org', whitelabel_api_public_key: build(:api_public_key), whitelabel_api_key: build(:api_key)) }
  let!(:account) { create(:static_account, id: 11111111, managed_mission: active_whitelabel_mission) }

  explanation 'Create, update, delete and retrieve account wallets.'

  header 'API-Key', build(:api_key)
  header 'Content-Type', 'application/json'

  get '/api/v1/accounts/:id/wallets' do
    with_options with_example: true do
      parameter :id, 'account id', required: true, type: :string
      parameter :page, 'page number', type: :integer
    end

    with_options with_example: true do
      response_field :id, 'wallet id', type: :integer
      response_field :name, 'wallet name', type: :string
      response_field :address, 'wallet address', type: :string
      response_field :primary_wallet, 'primary wallet', type: :boolean
      response_field :source, "wallet source #{Wallet.sources.keys}", type: :string
      response_field :state, "wallet state #{OreIdAccount.states.keys}", type: :string
      response_field :blockchain, "wallet blockchain #{Wallet._blockchains.keys}", type: :string
      response_field :provision_tokens, 'wallet tokens which should be provisioned with state for each token', type: :array
      response_field :createdAt, 'creation timestamp', type: :string
      response_field :updatedAt, 'update timestamp', type: :string
    end

    context '200' do
      let!(:id) { account.managed_account_id }
      let!(:wallet) { create(:wallet, id: 11111112, account: account) }
      let!(:page) { 1 }

      example 'INDEX' do
        explanation 'Returns an array of wallet objects'

        request = build(:api_signed_request, '', api_v1_account_wallets_path(account_id: account.managed_account_id), 'GET', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end

  post '/api/v1/accounts/:id/wallets' do
    with_options with_example: true do
      parameter :address, 'wallet address', required: true, type: :string
      parameter :blockchain, "wallet blockchain #{Wallet._blockchains.keys}", required: true, type: :string
      parameter :source, "wallet source #{Wallet.sources.keys}", required: false, type: :string
      parameter :tokens_to_provision, 'array of params to tokens provision', required: false, type: :array
      parameter 'tokens_to_provision["token_id"]', 'token_id is required if tokens_to_provision provided', required: true, type: :string
      parameter 'tokens_to_provision["max_balance"]', 'max_balance is required for security tokens only', required: false, type: :string
      parameter 'tokens_to_provision["lockup_until"]', 'lockup_until is required for security tokens only', required: false, type: :string
      parameter 'tokens_to_provision["reg_group_id"]', 'reg_group_id is required for security tokens only', required: false, type: :string
      parameter 'tokens_to_provision["account_frozen"]', 'account_frozen is required for security tokens only', required: false, type: :string
    end

    context '201' do
      let!(:id) { account.managed_account_id }
      let!(:create_params) { { wallets: [{ blockchain: :bitcoin, address: build(:bitcoin_address_1), name: 'Wallet' }] } }

      example 'CREATE WALLET' do
        explanation 'Returns created wallets (See INDEX for response details)'

        request = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST', 'example.org')
        allow_any_instance_of(Wallet).to receive(:id).and_return(21)
        do_request(request)
        expect(status).to eq(201)
      end
    end

    context '201' do
      let!(:id) { account.managed_account_id }
      let!(:create_params) { { wallets: [{ blockchain: :algorand_test, source: :ore_id, name: 'Wallet' }] } }

      example 'CREATE WALLET – ORE_ID' do
        explanation 'Returns created wallets (See INDEX for response details)'

        request = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST', 'example.org')
        allow_any_instance_of(Wallet).to receive(:id).and_return(22)
        do_request(request)
        expect(status).to eq(201)
      end
    end

    context '201' do
      let!(:id) { account.managed_account_id }
      let(:asa_token) { create(:asa_token, id: 11111113) }
      let(:ast_token) { create(:algo_sec_token, id: 11111114) }
      let(:reg_group) { create(:reg_group, id: 11111115, token: ast_token) }
      let(:tokens_to_provision) do
        [
          { token_id: asa_token.id.to_s },
          { token_id: ast_token.id.to_s, max_balance: '100', lockup_until: '1', reg_group_id: reg_group.id.to_s, account_frozen: 'false' }
        ]
      end
      let(:create_params) { { wallets: [{ blockchain: :algorand_test, source: :ore_id, tokens_to_provision: tokens_to_provision, name: 'Wallet name' }] } }

      example 'CREATE WALLET – ORE_ID WITH PROVISIONING' do
        explanation 'Returns created wallets (See INDEX for response details)'

        request = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST', 'example.org')
        allow_any_instance_of(Wallet).to receive(:id).and_return(23)
        do_request(request)
        expect(status).to eq(201)
      end
    end

    context '400' do
      let!(:id) { account.managed_account_id }
      let!(:create_params) { { wallets: [{ address: build(:bitcoin_address_1), name: 'Wallet' }] } }

      example 'CREATE WALLET – ERROR' do
        explanation 'Returns an array of errors'

        request = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST', 'example.org')
        do_request(request)
        expect(status).to eq(400)
        expect(response_body).to eq '{"errors":{"0":{"blockchain":["unknown blockchain value"]}}}'
      end
    end
  end

  put '/api/v1/accounts/:id/wallets/:wallet_id' do
    with_options with_example: true do
      parameter :id, 'account id', required: true, type: :string
      parameter :wallet_id, 'wallet id', required: true, type: :string
    end

    with_options with_example: true do
      parameter :primary_wallet, 'primary wallet flag', required: false, type: :boolean
    end

    context '200' do
      let!(:id) { account.managed_account_id }
      let!(:wallet_id) { create(:wallet, id: 11111116, account: account).id.to_s }
      let(:update_params) { { wallet: { primary_wallet: true } } }

      example 'UPDATE WALLET' do
        explanation 'Returns updated wallet (See INDEX for response details)'

        request = build(:api_signed_request, update_params, api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet_id), 'PUT', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end

  get '/api/v1/accounts/:id/wallets/:wallet_id' do
    with_options with_example: true do
      parameter :id, 'account id', required: true, type: :string
      parameter :wallet_id, 'wallet id', required: true, type: :string
    end

    with_options with_example: true do
      response_field :id, 'wallet id', type: :integer
      response_field :address, 'wallet address', type: :string
      response_field :primary_wallet, 'primary wallet', type: :boolean
      response_field :source, "wallet source #{Wallet.sources.keys}", type: :string
      response_field :state, "wallet state #{OreIdAccount.states.keys}", type: :string
      response_field :blockchain, "wallet blockchain #{Wallet._blockchains.keys}", type: :string
      response_field :tokens, 'wallet tokens', type: :array
      response_field :provision_tokens, 'wallet tokens which should be provisioned with state for each token', type: :array
      response_field :createdAt, 'creation timestamp', type: :string
      response_field :updatedAt, 'update timestamp', type: :string
    end

    context '200' do
      let!(:id) { account.managed_account_id }
      let!(:wallet_id) { create(:wallet, id: 11111117, account: account).id.to_s }

      example 'GET WALLET' do
        explanation 'Returns specified wallet (See INDEX for response details)'

        request = build(:api_signed_request, '', api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet_id), 'GET', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end

  delete '/api/v1/accounts/:id/wallets/:wallet_id' do
    with_options with_example: true do
      parameter :id, 'account id', required: true, type: :string
      parameter :wallet_id, 'wallet id to remove', required: true, type: :string
    end

    context '200' do
      let!(:id) { account.managed_account_id }
      let!(:wallet_id) { create(:wallet, id: 11111118, account: account).id.to_s }

      example 'REMOVE WALLET' do
        explanation 'Returns account wallets (See INDEX for response details)'

        request = build(:api_signed_request, '', api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet_id), 'DELETE', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end

  post '/api/v1/accounts/:id/wallets/:wallet_id/password_reset' do
    with_options with_example: true do
      parameter :id, 'account id', required: true, type: :string
      parameter :wallet_id, 'wallet id', required: true, type: :string
      parameter :redirect_url, 'url to redirect after password change', required: true, type: :string
    end

    with_options with_example: true do
      response_field :resetUrl, 'reset password url', type: :string
    end

    context '200' do
      let!(:id) { account.managed_account_id }
      let!(:wallet) { create(:ore_id_wallet, id: 11111119, account: account) }
      let(:wallet_id) { wallet.id.to_s }
      let!(:redirect_url) { 'localhost' }

      example 'GET RESET PASSWORD URL (ONLY ORE_ID WALLETS)' do
        explanation 'Returns reset password url for wallet'
        wallet.ore_id_account.update(account_name: 'ore_id_account_dummy', state: 'unclaimed')

        request = build(:api_signed_request, { redirect_url: redirect_url }, password_reset_api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet_id), 'POST', 'example.org')

        allow_any_instance_of(OreIdService).to receive(:create_token).and_return('dummy_token')
        allow_any_instance_of(OreIdService).to receive(:remote).and_return({ 'email' => account.email })
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end
end
