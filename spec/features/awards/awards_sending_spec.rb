require 'rails_helper'

describe 'awarding users' do
  let!(:team) { create :team }
  let!(:other_team) { create :team }
  let!(:account) { create(:account, email: 'hubert@example.com') }
  let!(:other_account) { create(:account, email: 'sherman@example.com') }
  let!(:different_team_account) { create(:account, email: 'different@example.com') }

  let!(:owner_authentication) { create(:authentication, account: account) }
  let!(:other_authentication) { create(:authentication, account: other_account) }
  let!(:different_team_authentication) { create(:authentication, account: different_team_account) }

  let!(:project) { create(:project, title: 'Project that needs awards', account: account, ethereum_enabled: true, ethereum_contract_address: '0x' + '2' * 40) }
  let!(:same_team_project) { create(:project, title: 'Same Team Project', account: account) }
  let!(:different_team_project) { create(:project, public: true, title: 'Different Team Project', account: different_team_account) }

  let!(:channel) { create(:channel, team: team, project: project, name: 'channel') }
  let!(:other_channel) { create(:channel, team: other_team, project: different_team_project, name: 'other channel') }

  let!(:small_award_type) { create(:award_type, project: project, name: 'Small', amount: 1000) }
  let!(:large_award_type) { create(:award_type, project: project, name: 'Large', amount: 3000) }

  let!(:same_team_small_award_type) { create(:award_type, project: same_team_project, name: 'Small', amount: 10) }
  let!(:same_team_small_award) { create(:award, issuer: account, account: account, award_type: same_team_small_award_type) }

  let!(:different_large_award_type) { create(:award_type, project: different_team_project, name: 'Large', amount: 3000) }
  let!(:different_large_award) { create(:award, issuer: different_team_account, award_type: different_large_award_type, account: different_team_account) }

  before do
    team.build_authentication_team owner_authentication
    team.build_authentication_team other_authentication
    other_team.build_authentication_team different_team_authentication

    travel_to(DateTime.parse('Mon, 29 Feb 2016 00:00:00 +0000')) # so we can check for fixed date of award

    stub_slack_user_list([{ "id": 'U99M9QYFQ', "team_id": 'team id', "name": 'bobjohnson', "profile": { "email": 'bobjohnson@example.com' } }])
    stub_request(:post, 'https://slack.com/api/users.info').to_return(body: {
      ok: true,
      "user": {
        "id": 'U99M9QYFQ',
        "team_id": 'team id',
        "name": 'bobjohnson',
        "profile": {
          email: 'bobjohnson@example.com'
        }
      }
    }.to_json)
  end

  after do
    travel_back
  end

  describe "when a user doesn't have an account for yet" do
    it 'populates the dropdown to select the awardee and creates the account/auth for the user' do
      expect_any_instance_of(Account).to receive(:send_award_notifications)
      login(account)

      visit project_path(project)

      expect(page.find('.my-share')).to have_content '0'

      fill_in :award_quantity, with: '1.579'
      select "[slack] #{team.name} ##{channel.name}", from: 'Communication Channel'

      fill_in 'Email Address', with: 'U99M9QYFQ'

      click_button 'Send'

      expect(page).to have_content 'Successfully sent award to bobjohnson'

      bobjohnsons_auth = Authentication.find_by(uid: 'U99M9QYFQ')
      expect(bobjohnsons_auth).not_to be_nil

      login(bobjohnsons_auth.account)

      visit project_awards_path(project)

      expect(page).to have_content 'bobjohnson'

      click_link('Overview')

      within('.meter-box') do
        expect(page.find('.my-share')).to have_content '1,579'
      end

      click_link 'Contributors'

      within('.contributors') do
        expect(page.find('.contributor')).to have_content 'bobjohnson'
        expect(page.find('.award-holdings')).to have_content '1,579'
      end
    end
  end

  it 'for a user with an account but no ethereum address' do
    login(other_account)

    visit root_path

    within('.project', text: 'Project that needs awards') do
      click_link 'Project that needs awards'
    end

    expect(page).to have_content('Project that needs awards')
    expect(page).not_to have_content('Send Award')
    expect(page).not_to have_content('User')

    login(account)

    visit project_path(project)

    click_link 'Awards'

    expect(page.all('.award-rows .award-row').size).to eq(0)

    expect(page).to have_content('Project Tokens Awarded')

    click_link 'Overview'

    expect(page).to have_content('Project that needs awards')

    click_button 'Send'

    expect(page).to have_content 'Failed sending award'

    within('.award-types') do
      expect(page.all('input[type=text]').size).to eq(2)
    end

    expect(page.all('select#award_channel_id option').map(&:text).sort).to eq(['Email', "[slack] #{team.name} ##{channel.name}"])
    fill_in 'Description', with: 'Super fantastic fabulous programatic work on teh things, A++'
    fill_in 'Email Address', with: 'tester@test.st'

    click_button 'Send'

    expect(page).to have_content 'Successfully sent award to tester@...'

    click_link 'Awards'

    expect(EthereumTokenIssueJob.jobs.length).to eq(0)

    expect(page).to have_content 'Project Tokens Awarded'
    expect(page).to have_content 'Feb 29'
    expect(page).to have_content '1,000'
    expect(page).to have_content '(no account)'
    expect(page).to have_content 'Small'
    expect(page).to have_content 'Super fantastic fabulous programatic work on teh things, A++'
    expect(page).to have_content 'tester@...'

    expect(page.all('.award-rows .award-row').size).to eq(1)

    click_link 'Overview'

    expect(page).to have_content('Project that needs awards')

    visit landing_projects_path
  end

  it 'awarding a user with an ethereum account' do
    expect_any_instance_of(Account).to receive(:send_award_notifications)
    create(:account, nickname: 'bobjohnson', email: 'bobjohnson@example.com', ethereum_wallet: '0x' + 'a' * 40)

    login(account)
    visit project_path(project)
    select "[slack] #{team.name} ##{channel.name}", from: 'Communication Channel'
    fill_in 'Email Address', with: 'U99M9QYFQ'
    click_button 'Send'

    expect(page).to have_content 'Successfully sent award to bobjohnson'
    expect(EthereumTokenIssueJob.jobs.length).to eq(1)
    expect(EthereumTokenIssueJob.jobs.first['args']).to eq([Award.last.id])
  end
end
