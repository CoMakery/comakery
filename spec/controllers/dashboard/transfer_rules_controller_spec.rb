require 'rails_helper'

RSpec.describe Dashboard::TransferRulesController, type: :controller do
  let!(:token) { create(:algo_sec_token, contract_address: '13997710') }
  let!(:project) { create(:project, visibility: :public_listed, token: token) }

  before do
    login(project.account)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index, params: { project_id: project.to_param }
      expect(response).to be_successful
    end
  end

  describe 'POST #create', :vcr do
    let(:valid_attributes) do
      {
        sending_group_id: RegGroup.find_or_create_by!(token_id: token.id, blockchain_id: 100),
        receiving_group_id: RegGroup.find_or_create_by!(token_id: token.id, blockchain_id: 200),
        lockup_until: 1
      }
    end

    let(:invalid_attributes) do
      {
        sending_group_id: 0,
        receiving_group_id: 100,
        lockup_until: 'dummy'
      }
    end

    subject { post :create, params: { project_id: project.id, transfer_rule: attributes } }

    context 'with valid params' do
      let(:attributes) { valid_attributes }

      it 'creates a new record' do
        expect { subject }.to change(project.token.transfer_rules, :count).by(1)
      end

      context 'with a request coming from ore-id controller' do
        before do
          request.headers['X-Sign-Controller'] = 'ore-id'
        end

        it 'redirects to ore_id' do
          subject
          expect(response).to have_http_status(:found)
        end
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
    end

    context 'with invalid params' do
      let(:attributes) { invalid_attributes }

      it 'doesnt create a new record' do
        expect { subject }.not_to change(project.token.transfer_rules, :count)
      end

      context 'with algorand security token', :vcr do
        it 'redirects to index' do
          subject
          expect(response).to redirect_to(project_dashboard_transfer_rules_path(project))
        end
      end
    end
  end

  describe 'DELETE #destroy', :vcr do
    let!(:transfer_rule) { create(:transfer_rule, token: token) }
    subject { delete :destroy, params: { project_id: project.id, id: transfer_rule.id } }

    it 'creates a new record with 0 lockup_until' do
      expect { subject }.to change(project.token.transfer_rules, :count).by(1)

      new_rule = project.token.transfer_rules.last
      expect(new_rule.sending_group_id).to eq(transfer_rule.sending_group_id)
      expect(new_rule.receiving_group_id).to eq(transfer_rule.receiving_group_id)
      expect(new_rule.lockup_until).to eq(Time.zone.at(0))
    end

    context 'with a request coming from ore-id controller' do
      before do
        request.headers['X-Sign-Controller'] = 'ore-id'
      end

      it 'redirects to ore_id' do
        subject
        expect(response).to have_http_status(:found)
      end
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
  end

  describe 'POST #freeze' do
    subject { post :freeze, params: { project_id: project.id } }

    it 'redirects to ore_id' do
      subject
      expect(response).to have_http_status(:found)
    end
  end

  describe 'POST #refresh_from_blockchain' do
    context 'when rules have been refreshed recently' do
      let!(:transfer_rule) { create(:transfer_rule, token: token, status: :synced, synced_at: Time.current) }

      it 'does not run refresh job' do
        expect(AlgorandSecurityToken::TransferRulesSyncJob).not_to receive(:perform_now)
        post :refresh_from_blockchain, params: { project_id: project.to_param }

        expect(response).to redirect_to(project_dashboard_transfer_rules_path(project))
        expect(transfer_rule.reload.status).to eq 'synced'
      end
    end

    context 'when rules have not been refreshed recently' do
      let!(:transfer_rule) { create(:transfer_rule, token: token, status: :synced, synced_at: 20.minutes.ago) }

      context 'with algorand security token', :vcr do
        it 'runs refresh job' do
          expect(AlgorandSecurityToken::TransferRulesSyncJob).to receive(:perform_now).and_return(true)
          post :refresh_from_blockchain, params: { project_id: project.to_param }

          expect(response).to redirect_to(project_dashboard_transfer_rules_path(project))
          expect(transfer_rule.reload.status).to eq 'outdated'
        end
      end

      context 'with comakery security token' do
        let!(:token) { create(:comakery_dummy_token) }
        let!(:project) { create(:project, visibility: :public_listed, token: token) }

        it 'runs refresh job' do
          expect(BlockchainJob::ComakerySecurityTokenJob::TransferRulesSyncJob).to receive(:perform_now).and_return(true)
          post :refresh_from_blockchain, params: { project_id: project.to_param }

          expect(response).to redirect_to(project_dashboard_transfer_rules_path(project))
          expect(transfer_rule.reload.status).to eq 'outdated'
        end
      end
    end
  end
end
