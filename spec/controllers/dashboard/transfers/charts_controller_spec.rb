# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Transfers::ChartsController, type: :controller do
  let(:account) { FactoryBot.create(:account) }

  let(:token) { FactoryBot.create(:token) }

  let(:project) do
    FactoryBot.create(:project, account: account, token: token, visibility: :public_listed,
                                require_confidentiality: false)
  end

  let(:earned_transfer_type) { FactoryBot.create(:transfer_type, project: project, name: 'earned') }

  let(:burn_transfer_type) { FactoryBot.create(:transfer_type, project: project, name: 'burn') }

  let(:award_type) { FactoryBot.create(:award_type, project: project) }

  let(:award1) do
    FactoryBot.create(:award, project: project, status: :paid, transfer_type: earned_transfer_type,
                              created_at: Time.zone.local(2021, 5, 24), amount: 5, quantity: 2,
                              award_type: award_type)
  end

  let(:award2) do
    FactoryBot.create(:award, project: project, status: :paid, transfer_type: burn_transfer_type,
                              created_at: Time.zone.local(2021, 6, 2), amount: 13,
                              award_type: award_type)
  end

  describe 'GET #index' do
    context 'when success' do
      shared_examples 'assign data and render chart partial' do
        it do
          expect(assigns(:project)).to eq project
          expect(assigns(:q)).to be_an_instance_of Ransack::Search
          expect(assigns(:unfiltered_transfers)).to eq project.awards.completed_or_cancelled.not_burned
          expect(assigns(:transfer_type_counts)).to eq({})
          expect(assigns(:transfer_type_name)).to eq nil

          expect(response).to render_template 'dashboard/transfers/_chart'
        end
      end

      context 'when authenticated' do
        before do
          get :index, params: { project_id: project.id, q: { filter: 'search_query' } }
        end

        it_behaves_like 'assign data and render chart partial'
      end

      context 'when not authenticated while project does not require confidentiality' do
        before do
          logout
          get :index, params: { project_id: project.id, q: { filter: 'search_query' } }
        end

        it_behaves_like 'assign data and render chart partial'
      end
    end

    context 'when failure' do
      context 'when not authorized' do
        let(:project) do
          FactoryBot.create(:project, account: account, token: token, visibility: :public_listed,
                                      require_confidentiality: true)
        end
        let(:other_account) { FactoryBot.create(:account) }

        before do
          login(other_account)

          get :index, params: { project_id: project.id }
        end

        it 'should redirect to root page' do
          expect(response).to redirect_to root_path

          expect(assigns(:project)).to eq project
        end
      end

      context 'when not found' do
        before do
          get :index, params: { project_id: 'fake' }
        end

        it 'should redirect to 404 page' do
          expect(response).to redirect_to '/404.html'

          expect(assigns(:project)).to eq nil
        end
      end
    end
  end
end
