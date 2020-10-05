require 'rails_helper'
require 'controllers/api/v1/concerns/requires_an_authorization_spec'
require 'controllers/api/v1/concerns/requires_signature_spec'
require 'controllers/api/v1/concerns/requires_whitelabel_mission_spec'
require 'controllers/api/v1/concerns/authorizable_by_mission_key_spec'

RSpec.describe Api::V1::WalletsController, type: :controller do
  it_behaves_like 'requires_an_authorization'
  it_behaves_like 'requires_signature'
  it_behaves_like 'requires_whitelabel_mission'
  it_behaves_like 'authorizable_by_mission_key'

  let!(:active_whitelabel_mission) { create(:active_whitelabel_mission) }
  let!(:account) { create(:account, managed_mission: active_whitelabel_mission) }
  let!(:project) { create(:project, mission: active_whitelabel_mission) }

  before do
    allow(controller).to receive(:authorized).and_return(true)
  end

  describe 'GET #index' do
    it 'returns account wallets' do
      params = build(:api_signed_request, '', api_v1_account_wallets_path(account_id: account.managed_account_id), 'GET')
      params[:account_id] = account.managed_account_id
      params[:format] = :json

      get :index, params: params
      expect(response).to be_successful
    end

    it 'applies pagination' do
      params = build(:api_signed_request, '', api_v1_account_wallets_path(account_id: account.managed_account_id), 'GET')
      params.merge!(account_id: account.managed_account_id, format: :json, page: 9999)

      get :index, params: params
      expect(response).to be_successful
      expect(assigns[:wallets]).to eq([])
    end
  end

  describe 'POST #create' do
    let(:create_params) { { wallet: { blockchain: :bitcoin, address: build(:bitcoin_address_1) } } }

    context 'with valid params' do
      it 'adds wallet to requested account' do
        expect do
          params = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST')
          params[:account_id] = account.managed_account_id

          post :create, params: params
        end.to change(account.wallets, :count).by(1)
      end

      it 'returns list of account wallets' do
        params = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST')
        params[:account_id] = account.managed_account_id

        post :create, params: params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      before do
        account.wallets.create(_blockchain: :bitcoin, address: build(:bitcoin_address_1))
      end

      it 'renders an error' do
        params = build(:api_signed_request, create_params, api_v1_account_wallets_path(account_id: account.managed_account_id), 'POST')
        params[:account_id] = account.managed_account_id

        post :create, params: params
        expect(response).not_to be_successful
        expect(assigns[:errors]).not_to be_nil
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid params' do
      let!(:wallet) { account.wallets.create(_blockchain: :bitcoin, address: build(:bitcoin_address_1)) }

      it 'removes the wallet from the requested account' do
        expect do
          params = build(:api_signed_request, '', api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet.id.to_s), 'DELETE')
          params[:account_id] = account.managed_account_id
          params[:id] = wallet.id

          delete :destroy, params: params
        end.to change(account.wallets, :count).by(-1)
      end

      it 'returns list of account wallets' do
        params = build(:api_signed_request, '', api_v1_account_wallet_path(account_id: account.managed_account_id, id: wallet.id.to_s), 'DELETE')
        params[:account_id] = account.managed_account_id
        params[:id] = wallet.id

        delete :destroy, params: params
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
