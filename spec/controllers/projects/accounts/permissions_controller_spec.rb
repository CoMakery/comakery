require 'rails_helper'

RSpec.describe Projects::Accounts::PermissionsController, type: :controller do
  let!(:admin) { create(:account) }
  let!(:project) { create(:project, account: admin) }
  let!(:account) { create(:account, email: 'example@gmail.com') }
  let!(:project_role) { create(:project_role, project: project, account: account, role: :interested) }

  let!(:params) do
    {
      id: project_role.id,
      project_id: project.id,
      account_id: account.id,
      project_role: { role: :admin }
    }
  end

  before do
    login(project.account)
  end

  describe 'GET #show' do
    it 'renders a successful response' do
      get :show, params: params, as: :turbo_stream
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST #update' do
    it 'updates permissions' do
      put :update, params: params, format: :json
      expect(project_role.reload.role).to eq('admin')
      expect(response).to have_http_status(:ok)
    end
  end
end
