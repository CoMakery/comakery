require 'rails_helper'
require 'controllers/api/v1/concerns/requires_an_authorization_spec'
require 'controllers/api/v1/concerns/authorizable_by_mission_key_spec'
require 'controllers/api/v1/concerns/authorizable_by_project_key_spec'
require 'controllers/api/v1/concerns/authorizable_by_project_policy_spec'

RSpec.describe Api::V1::BlockchainTransactionsController, type: :controller do
  it_behaves_like 'requires_an_authorization'
  it_behaves_like 'authorizable_by_mission_key'
  it_behaves_like 'authorizable_by_project_key'
  it_behaves_like 'authorizable_by_project_policy'

  let!(:active_whitelabel_mission) { create(:active_whitelabel_mission) }
  let!(:blockchain_transaction) { create(:blockchain_transaction) }
  let!(:project) { blockchain_transaction.blockchain_transactable.project }
  let!(:valid_create_attributes) do
    {
      transaction: {
        source: build(:ethereum_address_1),
        nonce: 1
      }
    }
  end

  before do
    project.update(mission: active_whitelabel_mission, hot_wallet_mode: :auto_sending)
    allow(controller).to receive(:authorized).and_return(true)
  end

  describe 'POST #create', vcr: true do
    context 'with awards available for transaction' do
      let!(:award) { create(:award, status: :accepted, award_type: create(:award_type, project: project)) }
      let!(:wallet) { create(:wallet, account: award.account, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }

      it 'creates a new BlockchainTransaction' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        expect do
          post :create, params: params
        end.to change(project.blockchain_transactions, :count).by(1)

        expect(project.blockchain_transactions.last).to be_a(BlockchainTransactionAward)
      end

      it 'returns a success response' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params
        expect(response).to have_http_status(:created)
      end

      context 'with request from a hot wallet' do
        before do
          project.update(hot_wallet: hot_wallet, hot_wallet_mode: hot_wallet_mode)
        end

        context 'with registered hw and hot_wallet_mode is disabled' do
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }
          let(:hot_wallet_mode) { 'disabled' }

          it 'returns no_content' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:no_content)
          end
        end

        context 'with registered hw and hot_wallet_mode is manual_sending without prioritized transfers' do
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }
          let(:hot_wallet_mode) { 'manual_sending' }

          it 'returns no_content' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:no_content)
          end
        end

        context 'with registered hw and hot_wallet_mode is manual_sending with prioritized transfers' do
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }
          let(:hot_wallet_mode) { 'manual_sending' }

          it 'returns the created transaction' do
            award.update(prioritized_at: Time.zone.now)

            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:created)
          end
        end

        context 'with registered hw and hot_wallet_mode is auto_sending' do
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }
          let(:hot_wallet_mode) { 'auto_sending' }

          it 'returns the created transaction' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:created)
          end
        end

        context 'with registered hw and hot_wallet_mode is auto_sending with prioritized transfer' do
          let!(:prioritized_award) { create(:award, prioritized_at: Time.zone.now, account: award.account, status: :accepted, award_type: create(:award_type, project: project)) }
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }
          let(:hot_wallet_mode) { 'auto_sending' }

          it 'creates the prioritized transaction' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:created)
            expect(BlockchainTransactionAward.last.blockchain_transactable).to eq prioritized_award
          end
        end

        context 'with NOT registered hw and hot_wallet_mode is disabled' do
          let(:hot_wallet) { nil }
          let(:hot_wallet_mode) { 'disabled' }

          it 'returns the created transaction' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:no_content)
          end
        end

        context 'with registered hw and hot_wallet_mode is auto_sending but another source' do
          let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: project.token._blockchain, address: build(:ethereum_address_2)) }
          let(:hot_wallet_mode) { 'auto_sending' }

          it 'returns the created transaction' do
            params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
            params[:project_id] = project.id

            post :create, params: params
            expect(response).to have_http_status(:created)
          end
        end
      end
    end

    context 'with award batch available for transaction' do
      let!(:project) { create(:project, token: create(:lockup_token), transfer_batch_size: transfer_batch_size) }
      let!(:award) { create(:award, lockup_schedule_id: 0, commencement_date: Time.current, status: :accepted, award_type: create(:award_type, project: project)) }
      let!(:award2) { create(:award, lockup_schedule_id: 0, commencement_date: Time.current, status: :accepted, award_type: create(:award_type, project: project)) }
      let!(:wallet) { create(:wallet, account: award.account, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }

      context 'and transfer_batch_size is one' do
        let(:transfer_batch_size) { 1 }

        it 'creates a new single BlockchainTransaction' do
          params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
          params[:project_id] = project.id

          expect do
            post :create, params: params
          end.to change(project.blockchain_transactions, :count).by(1)

          expect(project.blockchain_transactions.last).to be_a(BlockchainTransactionAward)
          expect(project.blockchain_transactions.last.blockchain_transactables.count).to eq(1)
        end
      end

      context 'and transfer_batch_size is two' do
        let(:transfer_batch_size) { 2 }

        it 'creates a new batch BlockchainTransaction' do
          params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
          params[:project_id] = project.id

          expect do
            post :create, params: params
          end.to change(project.blockchain_transactions, :count).by(1)

          expect(project.blockchain_transactions.last).to be_a(BlockchainTransactionAward)
          expect(project.blockchain_transactions.last.blockchain_transactables.count).to eq(2)
        end
      end
    end

    context 'with account_token_records available for transaction' do
      let!(:account_token_record) { create(:account_token_record, account: project.account, token: project.token) }

      it 'creates a new BlockchainTransaction' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        expect do
          post :create, params: params
        end.to change(project.blockchain_transactions, :count).by(1)

        expect(project.blockchain_transactions.last).to be_a(BlockchainTransactionAccountTokenRecord)
      end

      it 'returns a success response' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with frozen token' do
      let!(:account_token_record) { create(:account_token_record, account: project.account, token: project.token) }

      before do
        project.token.update(token_frozen: true)
      end

      it 'returns an error' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'without transactables available for transaction' do
      it 'returns an error' do
        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with invalid token' do
      let!(:award) { create(:award, status: :accepted, award_type: create(:award_type, project: project)) }

      it 'returns an error' do
        project.token.update(_token_type: :btc, _blockchain: :bitcoin)

        params = build(:api_signed_request, valid_create_attributes, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'PUT #update', vcr: true do
    it 'marks transaction as pending' do
      params = build(:api_signed_request, { transaction: { tx_hash: '0' } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'PUT')
      params[:project_id] = project.id
      params[:id] = blockchain_transaction.id

      put :update, params: params
      expect(blockchain_transaction.reload.status).to eq('pending')
    end

    it 'returns a success response' do
      params = build(:api_signed_request, { transaction: { tx_hash: '0' } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'PUT')
      params[:project_id] = project.id
      params[:id] = blockchain_transaction.id

      put :update, params: params
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE #destroy', vcr: true do
    context 'with failed param' do
      it 'marks transaction as failed' do
        params = build(:api_signed_request, { transaction: { tx_hash: blockchain_transaction.tx_hash, failed: 'true' } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE')
        params[:project_id] = project.id
        params[:id] = blockchain_transaction.id

        delete :destroy, params: params
        expect(blockchain_transaction.reload.status).to eq('failed')
        expect(response).to have_http_status(:success)
      end
    end

    it 'marks transaction as cancelled' do
      params = build(:api_signed_request, { transaction: { tx_hash: blockchain_transaction.tx_hash } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE')
      params[:project_id] = project.id
      params[:id] = blockchain_transaction.id

      delete :destroy, params: params
      expect(response).to have_http_status(:success)
      expect(blockchain_transaction.reload.status).to eq('cancelled')
    end

    it 'switches hot wallet mode to manual' do
      params = build(:api_signed_request, { transaction: { tx_hash: blockchain_transaction.tx_hash, switch_hot_wallet_to_manual_mode: 'true' } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE')
      params[:project_id] = project.id
      params[:id] = blockchain_transaction.id

      expect(project.hot_wallet_mode).to eq('auto_sending')

      delete :destroy, params: params

      expect(response).to have_http_status(:success)
      expect(project.reload.hot_wallet_mode).to eq('manual_sending')
    end

    it 'does not switch disabled hot wallet mode' do
      params = build(:api_signed_request, { transaction: { tx_hash: blockchain_transaction.tx_hash, switch_hot_wallet_to_manual_mode: 'true' } }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE')
      params[:project_id] = project.id
      params[:id] = blockchain_transaction.id

      project.update(hot_wallet_mode: :disabled)

      expect(project.hot_wallet_mode).to eq('disabled')

      delete :destroy, params: params

      expect(response).to have_http_status(:success)
      expect(project.reload.hot_wallet_mode).to eq('disabled')
    end
  end
end
