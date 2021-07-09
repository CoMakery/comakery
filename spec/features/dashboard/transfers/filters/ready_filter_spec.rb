require 'rails_helper'

describe 'test_ready_filter', js: true do
  let(:owner) { create :account }
  let!(:project) { create :project, token: create(:comakery_dummy_token), account: owner, visibility: 'public_listed' }
  let!(:wallet) { create :wallet, account: owner, address: '0xD8655aFe58B540D8372faaFe48441AeEc3bec423', _blockchain: project.token._blockchain }
  let!(:project_award_type) { (create :award_type, project: project) }
  let!(:verification) { create(:verification, account: owner) }

  # TODO: Remove me after fixing "eager loading detected Award => [:latest_transaction_batch]"
  before { Bullet.raise = false }

  [1, 5, 10].each do |number_of_transfers|
    context "With #{number_of_transfers} ready transfers" do
      it "Doesn't duplicate transfers" do
        number_of_transfers.times do
          create(:transfer, award_type: project_award_type, account: owner)
        end

        login(owner)
        visit project_path(project)
        click_link 'transfers'

        first(:css, '.transfers-table__transfer')

        # verify number of transfers before applying filter
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(number_of_transfers)

        select('ready', from: 'filter-status-select')
        page.find :xpath, '//select[@id="filter-status-select"]/option[@selected="selected" and contains (text(), "ready")]'

        # verify number of transfers after applying filter
        expect(page.all(:xpath, './/div[@class="transfers-table__transfer"]').size).to eq(number_of_transfers)
      end
    end
  end

  it 'orders by issuer first_name' do
    issuer1 = create(:account, first_name: 'John', last_name: 'Snow')
    issuer2 = create(:account, first_name: 'Ned', last_name: 'Stark')
    create(:transfer, award_type: project_award_type, account: owner, issuer: issuer1)
    create(:transfer, award_type: project_award_type, account: owner, issuer: issuer2)
    login(owner)
    visit project_path(project)
    click_link 'transfers'

    find('.transfers-table__transfer__issuer a.sort_link').click

    expect(find('.transfers-table__transfer__issuer a.sort_link.asc')).to have_content 'FROM ↓'
  end
end
