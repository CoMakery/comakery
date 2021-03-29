require 'rails_helper'

describe 'test_cancelled_filter', js: true do
  let(:owner) { create :account }
  let!(:project) { create :project, token: create(:comakery_dummy_token), account: owner }
  let!(:project_award_type) { (create :award_type, project: project) }

  [1, 6, 9].each do |number_of_transfers|
    context "With #{number_of_transfers} cancelled transfers" do
      it 'Returns correct number of transfers after applying filter' do
        number_of_transfers.times do
          create(:award, status: :cancelled, award_type: project_award_type)
        end

        login(owner)
        visit project_path(project)
        click_link 'transfers'
        page.find :css, '#select_transfers', wait: 20 # wait for page to load

        # verify number of transfers before applying filter is 0 (cancelled transfers are not displayed by default)
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(0)

        select('cancelled', from: 'transfers-filters--filter--options--select')
        page.find :xpath, '//select[@id="transfers-filters--filter--options--select"]/option[@selected="selected" and contains (text(), "cancelled")]', wait: 20 # wait for page to reload

        # verify number of transfers after applying filter
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(number_of_transfers)
      end
    end
  end
end
