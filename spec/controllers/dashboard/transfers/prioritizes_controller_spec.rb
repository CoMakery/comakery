# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Transfers::PrioritizesController, type: :controller do
  describe 'PATCH #update' do
    let(:project) { FactoryBot.create(:project) }

    let(:account) { project.account }

    let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }

    let(:award_type) { FactoryBot.create(:award_type, project: project) }

    let(:transfer) { FactoryBot.create(:award, status: :paid, award_type: award_type, transfer_type: transfer_type) }

    before { login(account) }

    it 'redirects with notice' do
      patch :update, params: { project_id: project.to_param, transfer_id: transfer.to_param }

      expect(response).to redirect_to(project_dashboard_transfers_path(project))

      expect(flash[:notice]).to eq('Transfer will be sent soon')
    end
  end
end
