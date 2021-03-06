require 'rails_helper'

describe 'landing page' do
  let!(:team) { create :team }
  let!(:account) { create(:account, nickname: 'gleenn', email: 'gleenn@example.com') }
  let!(:account1) { create(:account, nickname: 'Rick', email: 'rick@example.com') }
  let!(:authentication) { create :authentication, account: account }
  let!(:authentication1) { create :authentication, account: account1 }
  let!(:swarmbot_account) { create(:account, email: 'swarm@example.com') }
  let(:swarmbot_authentication) { create :authentication, account: swarmbot_account }
  let!(:interest) { create(:interest, account: account) }

  before do
    team.build_authentication_team authentication
    team.build_authentication_team authentication1
  end

  it 'when logged in shows some projects and the new button and ger buttons leading to edit respective projects' do
    login(account)

    project = create(:project, title: 'member Private Project', visibility: 'member', account: account1)
    project.channels.create(team: team, channel_id: 'channel')

    create(:project_role, project: project, account: account, role: :interested)

    7.times { |i| create(:project, account: swarmbot_account, title: "Public Project #{i}", visibility: 'public_listed') }
    7.times { |i| create(:project, title: "other Private Project #{i}", visibility: 'member') }
    7.times { |i| create(:project, account, title: "Private Project #{i}", visibility: 'member') }
    7.times { |i| create(:project, account, title: "Archived Project #{i}", visibility: 'archived') }

    visit my_project_path

    expect(page).to have_content 'mine'
    expect(page).to have_content 'interested'
    expect(page).to have_content(/new project/i)

    expect(page.all('.project').size).to eq(16)
    expect(page.first('a.fa.fa-cog')[:href]).to match(%r{/projects/\d+/edit})

    click_link 'Browse All'

    within('h2') { expect(page.text).to eq('Projects') }
    expect(page).to have_content(/new project/i)

    expect(page.all('.project').size).to eq(9)
  end

  it 'when logged out redirect to signup' do
    (1..3).each { |i| create(:project, account: swarmbot_account, title: "Featured Project #{i}", visibility: 'public_listed', featured: i) }
    (1..7).each { |i| create(:project, account: swarmbot_account, title: "Public Project #{i}", visibility: 'public_listed') }

    (1..7).each { |i| create(:project, account, title: "Private Project #{i}", public: false) }

    visit my_project_path

    expect(page.all('.project').size).to eq(0)
    expect(page.current_path).to eq('/accounts/new')
  end
end
