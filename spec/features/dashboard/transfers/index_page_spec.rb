require 'rails_helper'

describe 'transfers_index_page', js: true do
  let(:owner) { create :account }
  let!(:project) { create :project, token: nil, account: owner }
  let!(:project_award_type) { (create :award_type, project: project) }

  it 'returns transfers ordered by create desc' do
    create(:award, name: 'second', status: :paid, award_type: project_award_type)
    create(:award, name: 'first', status: :paid, award_type: project_award_type)

    login(owner)
    visit project_dashboard_transfers_path(project)
    page.find :css, '#select_transfers', wait: 20 # wait for page to load

    expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(2)
    expect(page.all(:xpath, './/div[@class="transfers-table__transfer__name"]/h3/a').map(&:text)).to eq %w[first second]
  end

  context 'when project has an assigned hot walled' do
    before do
      create(:wallet, source: :hot_wallet, project_id: project.id)
    end

    it 'returns the hot wallet address and change the hot wallet mode through websocket' do
      login(owner)
      visit project_dashboard_transfers_path(project)

      expect(page).to have_content('Hot Wallet:')

      # Turbo update check
      expect(page).to have_content('Hot Wallet Mode')
      expect(project.hot_wallet_mode).to eq 'disabled'
      expect(page).to have_select('project_hot_wallet_mode', selected: 'Disabled')

      project.update(hot_wallet_mode: 'auto_sending')
      expect(page).to have_select('project_hot_wallet_mode', selected: 'Auto sending')

      project.update(hot_wallet_mode: 'manual_sending')
      expect(page).to have_select('project_hot_wallet_mode', selected: 'Manual sending')
    end
  end

  %w[earned bought].each do |transfer|
    context "when user select transfer #{transfer}" do
      it 'returns transfer form with category selected' do
        login(owner)
        visit project_dashboard_transfers_path(project)
        page.find :css, '#select_transfers', wait: 20

        expect(page).to have_select('select_transfers', selected: 'Create New Transfer')

        find('#select_transfers option', text: transfer, visible: false).click

        expect(page).to have_select('select_transfers', selected: transfer)

        page.find :css, '.transfers-table__transfer--new'

        expect(page).to have_select('select_category', selected: transfer.capitalize)
      end
    end
  end

  it 'redirect to Transfer Categories page' do
    login(owner)
    visit project_dashboard_transfers_path(project)

    expect(page).to have_select('select_transfers', selected: 'Create New Transfer')

    find('#select_transfers option', text: 'Manage Categories', visible: false).click

    expect(page).to have_select('select_transfers', selected: 'Manage Categories')

    wait_for_turbolinks
    expect(page).to have_content('Transfer Categories')
  end
end
