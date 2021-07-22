require 'rails_helper'

RSpec.describe Dashboard::AccountsController, type: :controller do
  let(:account_token_record) { create(:account_token_record) }
  let(:project) { create(:project, visibility: :public_listed, token: account_token_record.token) }
  let(:account) { account_token_record.account }
  let(:new_account) { create(:account) }

  describe 'GET #index' do
    subject { get :index, params: { project_id: project.to_param } }

    before { project.add_account(account) }

    context 'with eth security token' do
      it { is_expected.to have_http_status(:success) }

      it 'returns interested' do
        subject

        expect(assigns[:accounts]).to include(account)

        expect(assigns[:accounts].ids).to match_array([account.id])
      end
    end

    context 'with algorand security token' do
      let(:account_token_record) { build(:algo_sec_dummy_restrictions) }
      let(:project) { create(:project, visibility: :public_listed, token: account_token_record.token) }

      it { is_expected.to have_http_status(:success) }

      it 'returns interested' do
        subject

        expect(assigns[:accounts]).to include(account)

        expect(assigns[:accounts].ids).to match_array([account.id])
      end
    end

    context 'with a non-security token' do
      let(:project) { create(:project, visibility: :public_listed) }

      it { is_expected.to have_http_status(:success) }

      it 'returns interested' do
        subject

        expect(assigns[:accounts]).to include(project.account)

        expect(assigns[:accounts].ids).to match_array([project.account_id, account.id])
      end
    end

    context 'without token' do
      let(:project) { create(:project, visibility: :public_listed) }

      before { project.update!(token: nil) }

      it { is_expected.to have_http_status(:success) }

      it 'returns interested' do
        subject

        expect(assigns[:accounts]).to include(project.account)

        expect(assigns[:accounts].ids).to match_array([project.account_id, account.id])
      end
    end

    context 'with json format' do
      subject { get :index, params: { project_id: project.to_param, format: :json } }

      context 'and a ransack query not supplied' do
        it { is_expected.to have_http_status(:success) }

        it 'returns accounts' do
          subject
          expect(assigns[:accounts]).to match_array([project.account, account])
        end
      end

      context 'and a ransack query supplied' do
        subject { get :index, params: { 'q[nickname_cont]': account.nickname, project_id: project.to_param, format: :json } }

        it { is_expected.to have_http_status(:success) }

        it 'returns accounts' do
          subject
          expect(assigns[:accounts]).to match_array([account])
        end
      end
    end
  end

  describe 'GET #wallets' do
    subject { get :wallets, params: { project_id: project.to_param, id: account.id } }

    before do
      project.add_account(account)
      login(project.account)
    end

    it { is_expected.to have_http_status(:success) }

    it 'sets account' do
      subject
      expect(assigns[:account]).to eq(account)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) do
      {
        max_balance: '100',
        lockup_until: '1',
        reg_group_id: create(:reg_group, token: account_token_record.token).id.to_s,
        account_id: new_account.id.to_s,
        account_frozen: 'false'
      }
    end

    let(:invalid_attributes) do
      {
        max_balance: '-100',
        lockup_until: '1',
        reg_group_id: create(:reg_group, token: account_token_record.token).id.to_s,
        account_id: new_account.id.to_s,
        account_frozen: 'false'
      }
    end

    subject { post :create, params: { project_id: project.id, account_token_record: attributes } }

    before { login(project.account) }

    before { project.add_account(account_token_record.account) }

    context 'with valid params' do
      let(:attributes) { valid_attributes }

      it 'creates a new record' do
        expect { subject }.to change(project.token.account_token_records, :count).by(1)

        account_token_record = project.token.account_token_records.last
        expect(account_token_record.account).to eq new_account
        expect(account_token_record.wallet).to eq new_account.wallets.first
      end

      context 'with a request coming from wallet connect controller' do
        before do
          request.headers['X-Sign-Controller'] = 'wallet-connect'
        end

        render_views

        it 'renders json' do
          subject
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to include('tx_new_url')
          expect(JSON.parse(response.body)).to include('tx_receive_url')
        end
      end

      context 'with a request coming from metamask controller' do
        before do
          request.headers['X-Sign-Controller'] = 'metamask'
        end

        render_views

        it 'renders json' do
          subject
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)).to include('tx_new_url')
          expect(JSON.parse(response.body)).to include('tx_receive_url')
        end
      end

      context 'with a request coming from ore-id controller', :vcr do
        before do
          request.headers['X-Sign-Controller'] = 'ore-id'
        end

        it 'redirects to ore_id' do
          subject
          expect(response).to have_http_status(:found)
        end
      end
    end

    context 'with invalid params' do
      let(:attributes) { invalid_attributes }

      it 'renders an error' do
        subject
        expect(response).not_to be_successful
        expect(assigns[:errors]).not_to be_nil
      end
    end
  end

  describe 'GET #show' do
    before do
      project.add_account(account)
    end

    it 'returns a success response' do
      get :show, params: { project_id: project.id, id: account.id }, as: :turbo_stream
      expect(response.status).to eq 200
    end
  end

  describe 'POST #refresh_from_blockchain' do
    let(:account_token_record) { create(:blockchain_transaction_account_token_record_algo).blockchain_transactable }

    before { login(project.account) }

    context 'when accounts have been refreshed recently', :vcr do
      before do
        account_token_record.update!(status: :synced, synced_at: Time.zone.now)
      end

      it 'does not run refresh job' do
        expect(AlgorandSecurityToken::AccountTokenRecordsSyncJob).not_to receive(:perform_now)

        post :refresh_from_blockchain, params: { project_id: project.id }

        expect(response).to redirect_to(project_dashboard_accounts_path(project))
        expect(account_token_record.reload.status).to eq 'synced'
      end
    end

    context 'when accounts have not been refreshed recently' do
      context 'with algorand security token', :vcr do
        before do
          account_token_record.update!(status: :synced, synced_at: 20.minutes.ago)
        end

        it 'runs refresh job' do
          expect(AlgorandSecurityToken::AccountTokenRecordsSyncJob).to receive(:perform_now).and_return(true)
          post :refresh_from_blockchain, params: { project_id: project.id }

          expect(response).to redirect_to(project_dashboard_accounts_path(project))
          expect(account_token_record.reload.status).to eq 'outdated'
        end
      end

      context 'with comakery security token', :vcr do
        let(:account_token_record) { create(:account_token_record) }

        before do
          account_token_record.update!(status: :synced, synced_at: 20.minutes.ago)
        end

        it 'runs refresh job' do
          expect(BlockchainJob::ComakerySecurityTokenJob::AccountTokenRecordsSyncJob).to receive(:perform_now).and_return(true)
          post :refresh_from_blockchain, params: { project_id: project.id }

          expect(response).to redirect_to(project_dashboard_accounts_path(project))
          expect(account_token_record.reload.status).to eq 'outdated'
        end
      end
    end
  end
end
