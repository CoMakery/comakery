# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::Transfers::ExportsController, type: :controller do
  describe 'POST #create' do
    subject { post :create, params: { project_id: project.id } }

    let(:project) { FactoryBot.create(:project) }

    let(:account) { project.account }

    before do
      ActiveJob::Base.queue_adapter = :test

      login(account)
    end

    after { ActiveJob::Base.queue_adapter.enqueued_jobs.clear }

    it { is_expected.to redirect_to(project_dashboard_transfers_path(project)) }

    it { expect { subject }.to enqueue_job(ProjectExportTransfersJob) }
  end
end
