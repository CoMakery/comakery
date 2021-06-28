require 'rails_helper'

RSpec.describe OreIdSyncJob, type: :job do
  subject(:perform) { OreIdSyncJob.perform_now(ore_id.id) }

  let(:now) { Time.zone.local(2021, 6, 1, 15) }
  let(:self_reschedule_job) { double('OreIdSyncJob', perform_later: nil) }
  let!(:ore_id) { FactoryBot.create(:ore_id_account, state: :pending_manual) }

  before do
    allow(OreIdSyncJob).to receive(:set).with(any_args).and_return(self_reschedule_job)
    allow_any_instance_of(OreIdAccount).to receive(:create_remote!)
    allow(Sentry).to receive(:capture_exception)
    Timecop.freeze(now)
  end

  after { Timecop.return }

  shared_examples 'fails and reschedules itself with the delay' do |expected_delay|
    it do
      perform

      expect(described_class).to have_received(:set).with(wait: expected_delay).once
      expect(described_class).to have_received(:set).once
      expect(self_reschedule_job).to have_received(:perform_later).once

      expect(ore_id.synchronisations.last).to be_failed
      expect(Sentry).to have_received(:capture_exception).with(RuntimeError)
    end
  end

  shared_examples 'skips and reschedules itself with the delay' do |expected_delay|
    it do
      perform

      expect(described_class).to have_received(:set).with(wait: expected_delay).once
      expect(described_class).to have_received(:set).once
      expect(self_reschedule_job).to have_received(:perform_later).once

      expect(ore_id.synchronisations).to be_empty
      expect(Sentry).not_to have_received(:capture_exception)
    end
  end

  context 'when sync is allowed' do
    before { allow_any_instance_of(ore_id.class).to receive(:sync_allowed?).and_return(true) }

    it 'calls create_remote and sets synchronisation status to ok' do
      expect_any_instance_of(ore_id.class).to receive(:create_remote!)

      perform

      expect(ore_id.synchronisations.last).to be_ok
    end

    context 'and service raises an error' do
      before { allow_any_instance_of(ore_id.class).to receive(:create_remote!).and_raise }

      context 'when next sync allowed time is in the future' do
        before do
          allow_any_instance_of(ore_id.class)
            .to receive(:next_sync_allowed_after).and_return(1.hour.since(now))
        end

        it_behaves_like 'fails and reschedules itself with the delay', 1.hour
      end

      context 'when next sync allowed time is in the past' do
        before do
          allow_any_instance_of(ore_id.class)
            .to receive(:next_sync_allowed_after).and_return(1.hour.before(now))
        end

        it_behaves_like 'fails and reschedules itself with the delay', 0
      end
    end
  end

  context 'when sync is not allowed' do
    before { allow_any_instance_of(OreIdAccount).to receive(:sync_allowed?).and_return(false) }

    context 'when next sync allowed time is in the future' do
      before do
        allow(Sentry).to receive(:capture_exception).and_call_original
        allow_any_instance_of(ore_id.class)
          .to receive(:next_sync_allowed_after).and_return(1.hour.since(now))
      end

      it_behaves_like 'skips and reschedules itself with the delay', 1.hour
    end

    context 'when next sync allowed time is in the past' do
      before do
        allow_any_instance_of(ore_id.class)
          .to receive(:next_sync_allowed_after).and_return(1.hour.before(now))
      end

      it_behaves_like 'skips and reschedules itself with the delay', 0
    end
  end
end
