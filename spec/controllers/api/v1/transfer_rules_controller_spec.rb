require 'rails_helper'

RSpec.describe Api::V1::TransferRulesController, type: :controller do
  let!(:active_whitelabel_mission) { create(:active_whitelabel_mission) }
  let!(:transfer_rule) { create(:transfer_rule) }
  let!(:project) { create(:project, mission: active_whitelabel_mission, token: transfer_rule.token) }

  let(:valid_attributes) do
    {
      sending_group_id: create(:reg_group, token: transfer_rule.token).id.to_s,
      receiving_group_id: create(:reg_group, token: transfer_rule.token).id.to_s,
      lockup_until: '1'
    }
  end

  let(:invalid_attributes) do
    {
      sending_group_id: '945677752'
    }
  end

  let(:valid_session) { {} }

  let(:valid_headers) do
    {
      'API-Key' => build(:api_key)
    }
  end

  let(:invalid_headers) do
    {
      'API-Key' => '12345'
    }
  end

  before do
    request.headers.merge! valid_headers
  end

  describe 'GET #index' do
    it 'returns records' do
      params = build(:api_signed_request, '', api_v1_project_transfer_rules_path(project_id: project.id), 'GET')
      params[:project_id] = project.id
      params[:format] = :json

      get :index, params: params, session: valid_session
      expect(response).to be_successful
    end

    it 'applies pagination' do
      params = build(:api_signed_request, '', api_v1_project_transfer_rules_path(project_id: project.id), 'GET')
      params.merge!(project_id: project.id, format: :json, page: 9999)

      get :index, params: params, session: valid_session
      expect(response).to be_successful
      expect(assigns[:transfer_rules]).to eq([])
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      params = build(:api_signed_request, '', api_v1_project_transfer_rule_path(id: transfer_rule.id, project_id: project.id), 'GET')
      params.merge!(project_id: project.id, id: transfer_rule.id, format: :json)

      get :show, params: params, session: valid_session
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new record' do
        expect do
          params = build(:api_signed_request, { transfer_rule: valid_attributes }, api_v1_project_transfer_rules_path(project_id: project.id), 'POST')
          params[:project_id] = project.id

          post :create, params: params, session: valid_session
        end.to change(project.token.transfer_rules, :count).by(1)
      end

      it 'returns created record' do
        params = build(:api_signed_request, { transfer_rule: valid_attributes }, api_v1_project_transfer_rules_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params, session: valid_session
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid params' do
      it 'renders an error' do
        params = build(:api_signed_request, { transfer_rule: invalid_attributes }, api_v1_project_transfer_rules_path(project_id: project.id), 'POST')
        params[:project_id] = project.id

        post :create, params: params, session: valid_session
        expect(response).not_to be_successful
        expect(assigns[:errors]).not_to be_nil
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the record' do
      expect do
        params = build(:api_signed_request, '', api_v1_project_transfer_rule_path(project_id: project.id, id: transfer_rule.id), 'DELETE')
        params[:project_id] = project.id
        params[:id] = transfer_rule.id

        delete :destroy, params: params, session: valid_session
      end.to change(project.token.transfer_rules, :count).by(-1)
    end
  end
end
