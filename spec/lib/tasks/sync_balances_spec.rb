require 'rails_helper'

describe 'rake balances:sync_all', type: :task do
  it 'runs the sync job' do
    expect(SyncBalancesJob).to receive(:perform_now)
    task.execute
  end
end
