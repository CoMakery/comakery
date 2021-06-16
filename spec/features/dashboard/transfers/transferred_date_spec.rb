require 'rails_helper'

describe 'transferred date column', js: true do
  let!(:transfer) { build(:algorand_app_transfer_tx).blockchain_transaction.blockchain_transactable }

  let!(:project) { transfer.project }

  before do
    login(project.account)

    visit project_dashboard_transfers_path(project)
  end

  it { expect(page).to have_css('.transfers-table__transfer__transferred_at') }

  context 'when transfer is paid' do
    before do
      transfer.paid!
      visit project_dashboard_transfers_path(project)
    end

    it 'shows transferred date' do
      wait_for_turbolinks

      expect(find("#transfer_#{transfer.id}_transferred_date").text).to eq(DateTime.current.strftime('%b %-e, %Y'))
    end
  end
end
