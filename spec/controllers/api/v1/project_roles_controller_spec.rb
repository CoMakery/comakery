require 'rails_helper'
require 'controllers/api/v1/concerns/requires_an_authorization_spec'
require 'controllers/api/v1/concerns/requires_signature_spec'
require 'controllers/api/v1/concerns/requires_whitelabel_mission_spec'
require 'controllers/api/v1/concerns/authorizable_by_mission_key_spec'

RSpec.describe Api::V1::ProjectRolesController, type: :controller do
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
    it 'returns project involved accounts' do
      params = build(:api_signed_request, '', api_v1_account_project_roles_path(account_id: account.managed_account_id), 'GET')
      params[:account_id] = account.managed_account_id
      params[:format] = :json

      get :index, params: params
      expect(response).to be_successful
    end

    it 'applies pagination' do
      params = build(:api_signed_request, '', api_v1_account_project_roles_path(account_id: account.managed_account_id), 'GET')
      params.merge!(account_id: account.managed_account_id, format: :json, page: 9999)

      get :index, params: params
      expect(response).to be_successful
      expect(assigns[:project_involved_accounts]).to eq([])
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'involves the account in the project ' do
        params = build(:api_signed_request, { project_id: project.id.to_s }, api_v1_account_project_roles_path(account_id: account.managed_account_id), 'POST')
        params[:account_id] = account.managed_account_id

        post :create, params: params
        project.reload
        expect(project.project_interested).to include(account)
      end

      it 'returns list of project involved accounts' do
        params = build(:api_signed_request, { project_id: project.id.to_s }, api_v1_account_project_roles_path(account_id: account.managed_account_id), 'POST')
        params[:account_id] = account.managed_account_id

        post :create, params: params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      before do
        project.project_roles.create(account: account)
      end

      it 'renders an error' do
        params = build(:api_signed_request, { project_id: project.id.to_s }, api_v1_account_project_roles_path(account_id: account.managed_account_id), 'POST')
        params[:account_id] = account.managed_account_id

        post :create, params: params
        expect(response).not_to be_successful
        expect(assigns[:errors]).not_to be_nil
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'with valid params' do
      before do
        project.project_roles.create(account: account)
      end

      it 'is\'nt involved in the requested project ' do
        params = build(:api_signed_request, '', api_v1_account_project_role_path(account_id: account.managed_account_id, id: project.id), 'DELETE')
        params[:account_id] = account.managed_account_id
        params[:id] = project.id

        delete :destroy, params: params
        project.reload
        expect(project.project_interested).not_to include(account)
      end

      it 'returns list of project involved accounts' do
        params = build(:api_signed_request, '', api_v1_account_project_role_path(account_id: account.managed_account_id, id: project.id), 'DELETE')
        params[:account_id] = account.managed_account_id
        params[:id] = project.id

        delete :destroy, params: params
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
