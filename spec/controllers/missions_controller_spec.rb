require 'rails_helper'
require 'refile/file_double'

describe MissionsController do
  let!(:mission1) { create :mission, name: 'test1' }
  let!(:mission2) { create :mission, name: 'test2' }
  let!(:public_project1) { create :project, mission: mission1, visibility: :public_listed }
  let!(:public_award1) { create :award, award_type: create(:award_type, project: public_project1) }
  let!(:admin_account) { create :account, comakery_admin: true }
  let!(:account) { create :account }

  before do
    login(admin_account)
  end

  describe '#index' do
    context 'when not logged in' do
      it 'redirects to signup' do
        session[:account_id] = nil
        get :index
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_account_url)
      end
    end

    context 'when logged in without admin flag' do
      it 'redirects to root' do
        login(account)
        get :index
        expect(response.status).to eq(302)
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when logged in with admin flag' do
      it 'returns correct react component' do
        get :index
        expect(response.status).to eq(200)
        expect(assigns[:missions].count).to eq(3)
      end
    end

    it 'is available for whitelabel' do
      create :active_whitelabel_mission

      get :index
      expect(response.status).to eq(200)
      expect(assigns[:missions].count).to eq(4)
    end
  end

  describe '#new' do
    context 'when not logged in' do
      it 'redirects to signup' do
        session[:account_id] = nil
        get :new
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_account_url)
      end
    end

    context 'when logged in without admin flag' do
      it 'redirects to root' do
        login(account)
        get :new
        expect(response.status).to eq(302)
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when logged in with admin flag' do
      it 'returns correct react component' do
        get :new
        expect(response.status).to eq(200)
        expect(assigns[:mission]).to be_a_new_record
      end
    end
  end

  describe '#show' do
    it 'returns correct react component' do
      get :show, params: { id: mission1.id }
      expect(response.status).to eq(200)
    end
  end

  describe '#edit' do
    context 'when not logged in' do
      it 'redirects to signup' do
        session[:account_id] = nil
        get :edit, params: { id: mission1.id }
        expect(response.status).to eq(302)
        expect(response).to redirect_to(new_account_url)
      end
    end

    context 'when logged in without admin flag' do
      it 'redirects to root' do
        login(account)
        get :edit, params: { id: mission1.id }
        expect(response.status).to eq(302)
        expect(response).to redirect_to(root_url)
      end
    end

    context 'when logged in with admin flag' do
      it 'returns correct react component' do
        get :edit, params: { id: mission1.id }
        expect(response.status).to eq(200)
        expect(assigns[:mission]).to eq(mission1)
      end

      describe 'props' do
        subject { assigns[:props][:mission] }

        let(:mission) { create :whitelabel_mission }

        before do
          get :edit, params: { id: mission.id }
        end

        specify { expect(subject[:logo_url]).to include(mission.logo.filename.sanitized) }
        specify { expect(subject[:image_url]).to include(mission.image.filename.sanitized) }
        specify { expect(subject[:whitelabel_logo_url]).to include(mission.whitelabel_logo.filename.sanitized) }
        specify { expect(subject[:whitelabel_logo_dark_url]).to include(mission.whitelabel_logo_dark.filename.sanitized) }
        specify { expect(subject[:whitelabel_favicon_url]).to include(mission.whitelabel_favicon.filename.sanitized) }
      end
    end
  end

  describe '#create' do
    it 'creates a new mission' do
      expect do
        post :create, params: {
          mission: {
            name: 'test2',
            subtitle: 'test2',
            description: 'test2',
            image: fixture_file_upload('helmet_cat.png', 'image/png', :binary),
            logo: fixture_file_upload('helmet_cat.png', 'image/png', :binary)
          }
        }
        expect(response.status).to eq(200)
      end.to change { Mission.count }.by(1)
    end

    it 'renders error if param is blank' do
      expect do # rubocop:todo Lint/AmbiguousBlockAssociation
        post :create, params: {
          mission: {
            subtitle: 'test2',
            description: 'test2',
            logo: fixture_file_upload('helmet_cat.png', 'image/png', :binary)
          }
        }
        expect(response.status).to eq(422)
      end.not_to change { Mission.count }
    end
  end

  describe '#update' do
    subject { get :update, params: { id: mission.id, mission: attributes } }

    it 'updates a mission' do
      expect do
        put :update, params: { id: mission1, mission: { name: 'test1_name' } }
        expect(response.status).to eq(200)
      end.to change { mission1.reload.name }.from('test1').to('test1_name')
    end

    context 'with wallet_recovery_api_public_key given' do
      let(:mission) { mission1 }
      let(:attributes) do
        { wallet_recovery_api_public_key: '0x5633454c810b6e3c881e35f904a6215f1825e46429a54061d1b7448be1b4285e' }
      end

      it 'ignores wallet_recovery_api_public_key' do
        expect { subject }.not_to change(mission, :wallet_recovery_api_public_key)
      end
    end

    it 'renders error if param is blank' do
      expect do # rubocop:todo Lint/AmbiguousBlockAssociation
        put :update, params: { id: mission1, mission: { name: '' } }
        expect(response.status).to eq(422)
      end.not_to change { mission1.name }
    end

    it 'renders error if name is too long' do
      expect do # rubocop:todo Lint/AmbiguousBlockAssociation
        put :update, params: { id: mission1, mission: { name: 'a' * 101 } }
        expect(response.status).to eq(422)
      end.not_to change { mission1.name }
    end
  end

  describe '#rearrange' do
    it 'rearrange missions' do
      display_orders = [mission1.display_order, mission2.display_order]
      mission_ids = [mission1.id, mission2.id]
      expect do
        post :rearrange, params: { direction: -1, display_orders: display_orders, mission_ids: mission_ids }
        expect(response.status).to eq(200)
      end.to change { mission1.reload.display_order }.from(display_orders[0]).to(display_orders[1])
    end
  end
end
