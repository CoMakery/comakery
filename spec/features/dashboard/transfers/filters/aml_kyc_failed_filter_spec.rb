require 'rails_helper'

describe 'test_aml_kyc_failed_wallet_filter', js: true do
  let(:owner) { create :account }
  let!(:project) { create :project, token: create(:comakery_dummy_token), account: owner }
  let!(:project_award_type) { (create :award_type, project: project) }
  let!(:verification) { create(:verification, account: owner, passed: false) }

  # TODO: Remove me after fixing "eager loading detected Award => [:latest_transaction_batch]"
  before { Bullet.raise = false }

  [1, 2, 5].each do |number_of_transfers|
    context "With #{number_of_transfers} AML/KYC failed transfers" do
      it 'Returns correct number of transfers after applying filter' do
        number_of_transfers.times do
          create(:transfer, award_type: project_award_type, account: owner)
        end

        login(owner)
        visit project_path(project)
        click_link 'transfers'

        first(:css, '.transfers-table__transfer', wait: 20)

        # verify number of transfers before applying filter
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(number_of_transfers)

        select('blocked – AML/KYC failed', from: 'filter-status-select')
        page.find :xpath, '//select[@id="filter-status-select"]/option[@selected="selected" and contains (text(), "blocked – AML/KYC failed")]', wait: 20 # wait for page to reload

        # verify number of transfers after applying filter
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(number_of_transfers)
      end
    end
  end
end
