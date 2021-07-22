require 'rails_helper'

describe 'project channels', js: true do
  let!(:team) { create :team }
  let!(:account) { create :account }
  let!(:authentication) { create :authentication, account: account }
  let!(:project) { create :project, account: account }
  let!(:account1) { create :account }

  before do
    team.build_authentication_team authentication, true
    stub_slack_channel_list
  end

  it 'allows to manage channels' do
    login account
    visit new_project_path
    fill_in 'project[title]', with: 'This is a project'
    fill_in 'project[description]', with: 'This is a project description which is very informative'
    fill_in 'project[maximum_tokens]', with: '1000'
    fill_in 'project[video_url]', with: 'https://www.youtube.com/watch?v=Dn3ZMhmmzK0'
    attach_file 'project[square_image]', Rails.root.join('spec', 'fixtures', '1200.png') # rubocop:todo Rails/FilePath
    expect(page).not_to have_selector('.project-form--form--channels--channel')
    find('.project-form--form--channels--add').click
    expect(page).to have_selector('.project-form--form--channels--channel')
    find_button('create', { class: 'button__border' }).click
    expect(page).to have_content 'Project Created'

    visit current_path
    expect(page).to have_selector('.project-form--form--channels--channel')
    find('.project-form--form--channels--channel--del').click
    expect(page).not_to have_selector('.project-form--form--channels--channel')
    find_button('save').click
    expect(page).to have_content 'Project Updated'

    visit current_path
    expect(page).not_to have_selector('.project-form--form--channels--channel')
  end

  it 'displays message when auth is missing' do
    login account1
    visit new_project_path
    expect(page).not_to have_selector('.project-form--form--channels--add')
    expect(page).not_to have_selector('.project-form--form--channels--channel')
    expect(page).not_to have_content 'Start adding channels by signing in with Slack or Discord'
  end
end
