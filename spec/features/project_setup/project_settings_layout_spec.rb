require 'rails_helper'

describe 'project settings layout' do
  let!(:account) { create(:account, first_name: 'Glenn', last_name: 'Spanky', email: 'gleenn@example.com') }
  let!(:project) { create(:project, title: 'Cats with Lazers Project', description: 'cats with lazers', account: account, public: false) }

  before do
    Capybara.page.current_window.resize_to(3460, 1500) # (height, width)
    login(account)
  end

  it 'active menu item', js: true do
    visit edit_project_path(project)
    expect(page).to have_no_link('Communication Channels', class: 'active-menu')
    click_link 'Communication Channels'
    expect(page).to have_link('Communication Channels', class: 'active-menu')

    expect(page.evaluate_script("$('.content-box[data-id=visibility]').visible(true)")).to be false
    click_link 'Visibility'
    expect(page).to have_no_link('Communication Channels', class: 'active-menu')
    expect(page).to have_link('Visibility', class: 'active-menu')
    # expect(page.evaluate_script("$('.content-box[data-id=visibility]').visible(true)")).to be true
  end
end
