require 'rails_helper'

describe 'logging in and out' do
  let!(:team) { create :team }
  let!(:project) { create :project, title: 'This is a project', account: account }
  let!(:account) { create :account }
  let!(:authentication) { create :authentication, account_id: account.id }

  before do
    team.build_authentication_team authentication
    stub_slack_user_list
  end

  specify do
    page.set_rack_session(account_id: nil)

    visit root_path

    expect(page).to have_content 'SIGN IN'

    page.set_rack_session(account_id: account.id)

    visit project_path(project)

    expect(page).to have_content 'This is a project'

    first('.menu').click_link 'SIGN OUT'

    expect(page).to have_content 'SIGN IN'

    visit '/logout'

    expect(page).to have_content 'SIGN IN'
  end

  specify do
    account.update contributor_form: true
    page.set_rack_session(account_id: account.id)
    visit root_path
    expect(page).to have_content 'FIND THE PROJECTS THAT SPEAK TO YOU'
  end
end
