require 'rails_helper'

RSpec.describe Dashboard::TransfersController, type: :controller do
  let(:account) { FactoryBot.create(:account) }
  let(:token) { FactoryBot.create(:token) }
  let(:wallet) { FactoryBot.create(:wallet, account: account) }
  let(:balance) { FactoryBot.create(:balance, token: token, wallet: wallet) }
  let(:project) do
    FactoryBot.create :project, account: account, token: token, visibility: :public_listed
  end
  let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }
  let(:award_type) { FactoryBot.create(:award_type, project: project) }
  let(:transfer) do
    FactoryBot.create(:award, status: :paid, award_type: award_type, transfer_type: transfer_type)
  end

  let(:valid_attributes) do
    {
      amount: 2,
      quantity: 2,
      why: '-',
      price: 100,
      recipient_wallet_id: wallet.id,
      description: '-',
      requirements: '-',
      transfer_type_id: transfer_type.id.to_s,
      account_id: account.to_param
    }
  end

  let(:invalid_attributes) do
    {
      amount: 2,
      quantity: 2,
      why: '-',
      description: '-',
      requirements: '-',
      transfer_type_id: transfer_type.id.to_s,
      account_id: ''
    }
  end

  before { login(account) }

  describe 'GET #index' do
    context 'when success' do
      it 'returns a success response' do
        get :index, params: { project_id: project.to_param }
        expect(response).to be_successful
      end

      context 'when page is out of range' do
        it 'returns a success response with a notice' do
          get :index, params: { project_id: project.to_param, page: 9999 }
          expect(response).to be_successful
          expect(controller).to set_flash[:notice]
        end
      end

      context 'when a project has burn transfers' do
        let!(:award_type) { FactoryBot.create(:award_type, project: project) }
        let!(:burn_transfer_type) { FactoryBot.create(:transfer_type, project: project, name: 'burn') }
        let!(:burn_transfer) do
          FactoryBot.create :award, account: project.account, amount: 200, status: :paid, award_type: award_type,
                                    transfer_type: burn_transfer_type
        end

        it 'returns a success response with burn transfer record' do
          get :index, params: { project_id: project.to_param }

          expect(response).to be_successful

          expect(assigns[:transfers]).to include(burn_transfer)
        end
      end
    end

    context 'when failure' do
      context 'when statement invalid error' do
        before do
          allow_any_instance_of(Ransack::Search)
            .to receive(:result).and_raise(ActiveRecord::StatementInvalid)
          get :index, params: { project_id: project.to_param }
        end

        it 'should respond with 404 code' do
          expect(response.code).to eq '404'
          expect(response.body).to be_blank
        end
      end
    end
  end

  describe 'GET #show' do
    it 'returns a success response' do
      get :show, params: { project_id: project.to_param, id: transfer.to_param }
      expect(response).to be_successful
    end

    context 'for cancelled transfers' do
      let(:transfer) do
        FactoryBot.create :award, status: :cancelled, transfer_type: transfer_type,
                                  award_type: award_type
      end

      it 'returns a success response' do
        get :show, params: { project_id: project.to_param, id: transfer.to_param }

        expect(response).to be_successful
      end
    end
  end

  describe 'GET #edit' do
    context 'when success' do
      before { get :edit, params: { project_id: project.to_param, id: transfer.to_param } }

      it 'should respond with success and render edit' do
        expect(response).to be_successful
        expect(assigns(:project)).to eq project
        expect(assigns(:transfer)).to eq transfer
        expect(response).to render_template :edit
      end
    end

    context 'when failure' do
      context 'when not authenticated' do
        before do
          logout
          get :edit, params: { project_id: project.to_param, id: transfer.to_param }
        end

        it 'should redirect to sign up page' do
          expect(response).to redirect_to new_account_path
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
        end
      end

      context 'when not authorized' do
        let(:another_account) { FactoryBot.create(:account) }

        before do
          login(another_account)
          get :edit, params: { project_id: project.to_param, id: transfer.to_param }
        end

        it 'should redirect to root page' do
          expect(response).to redirect_to root_path
          expect(assigns(:project)).to eq project
          expect(assigns(:transfer)).to eq nil
        end
      end

      context 'when not found' do
        before { get :edit, params: { project_id: 'fake', id: transfer.to_param } }

        it 'should redirect to 404 page' do
          expect(response).to redirect_to '/404.html'
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:transfer) do
      FactoryBot.create :award, status: :paid, award_type: award_type, transfer_type: transfer_type,
                                description: 'Old desc', amount: 20
    end
    let(:transfer_params) { { description: Faker::Lorem.sentence(word_count: 3), amount: 10 } }

    context 'when success' do
      before do
        patch :update,
              params: { project_id: project.id, id: transfer.to_param, award: transfer_params }
      end

      it 'should update transfer and redirect to project transfers list on dashboard' do
        expect(response).to redirect_to project_dashboard_transfers_path(project)
        expect(assigns(:project)).to eq project
        expect(assigns(:transfer)).to eq transfer
        expect(transfer.reload).to have_attributes transfer_params
        expect(flash[:notice]).to eq 'Transfer Updated'
      end
    end

    context 'when failure' do
      context 'when invalid params' do
        let(:transfer_params) { { amount: -2 } }

        before do
          patch :update,
                params: { project_id: project.id, id: transfer.to_param, award: transfer_params }
        end

        it 'should not update transfer and redirect to project transfers list on dashboard' do
          expect(response).to redirect_to project_dashboard_transfers_path(project)
          expect(assigns(:project)).to eq project
          expect(assigns(:transfer)).to eq transfer
          expect(transfer.reload).to have_attributes description: 'Old desc', amount: 20
          expect(flash[:error]).to eq 'Amount must be greater than or equal to 0'
        end
      end

      context 'when not authenticated' do
        before do
          logout
          patch :update,
                params: { project_id: project.id, id: transfer.to_param, award: transfer_params }
        end

        it 'should redirect to sign up page' do
          expect(response).to redirect_to new_account_path
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
          expect(transfer.reload).to have_attributes description: 'Old desc', amount: 20
        end
      end

      context 'when not authorized' do
        let(:another_account) { FactoryBot.create(:account) }

        before do
          login(another_account)
          patch :update,
                params: { project_id: project.id, id: transfer.to_param, award: transfer_params }
        end

        it 'should redirect to root page' do
          expect(response).to redirect_to root_path
          expect(assigns(:project)).to eq project
          expect(assigns(:transfer)).to eq nil
          expect(transfer.reload).to have_attributes description: 'Old desc', amount: 20
        end
      end

      context 'when not found' do
        before do
          patch :update,
                params: { project_id: 'fake', id: transfer.to_param, award: transfer_params }
        end

        it 'should redirect to 404 page' do
          expect(response).to redirect_to '/404.html'
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
          expect(transfer.reload).to have_attributes description: 'Old desc', amount: 20
        end
      end
    end
  end

  describe 'GET #new' do
    let(:transfer_params) { { description: Faker::Lorem.sentence(word_count: 3), amount: 10 } }

    context 'when success' do
      before { get :new, params: { project_id: project.to_param, award: transfer_params } }

      it 'should respond with success and render new' do
        expect(response).to be_successful
        expect(assigns(:project)).to eq project
        expect(assigns(:transfer)).to be_an Award
        expect(assigns(:transfer).new_record?).to eq true
        expect(assigns(:transfer)).to have_attributes transfer_params
        expect(response).to render_template :new
      end
    end

    context 'when failure' do
      context 'when not authenticated' do
        before do
          logout
          get :new, params: { project_id: project.to_param, award: transfer_params }
        end

        it 'should redirect to sign up page' do
          expect(response).to redirect_to new_account_path
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
        end
      end

      context 'when not authorized' do
        let(:another_account) { FactoryBot.create(:account) }

        before do
          login(another_account)
          get :new, params: { project_id: project.to_param, award: transfer_params }
        end

        it 'should redirect to root page' do
          expect(response).to redirect_to root_path
          expect(assigns(:project)).to eq project
          expect(assigns(:transfer)).to eq nil
        end
      end

      context 'when not found' do
        before { get :new, params: { project_id: 'fake', award: transfer_params } }

        it 'should redirect to 404 page' do
          expect(response).to redirect_to '/404.html'
          expect(assigns(:project)).to eq nil
          expect(assigns(:transfer)).to eq nil
        end
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new transfer' do
        expect do
          post :create, params: { award: valid_attributes, project_id: project.to_param }
          expect(response).to redirect_to(project_dashboard_transfers_path(project))
        end.to change(project.awards, :count).by(1)

        award = project.reload.awards.last
        expect(award.name).to eq(award.transfer_type.name.titlecase)
        expect(award.issuer).to eq(project.account)
        expect(award.status).to eq('accepted')
        expect(award.price).to eq(100)
        expect(award.recipient_wallet).to eq(wallet)
      end
    end

    context 'with invalid params' do
      it 'redirects to transfers with error' do
        expect do
          post :create, params: { award: invalid_attributes, project_id: project.to_param }
          expect(response).to redirect_to(project_dashboard_transfers_path(project))
        end.not_to change(project.awards, :count)
      end
    end
  end
end
