require 'rails_helper'

feature 'pages' do
  let!(:account) { create :account, contributor_form: true }
  let(:mission_dummy_image) { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/helmet_cat.png').to_s, 'image/png') }
  let!(:token) { create :token }
  let!(:mission1) { create :mission, name: 'test1', token_id: token.id, image: mission_dummy_image }
  let!(:mission2) { create :mission, name: 'test2', token_id: token.id, image: mission_dummy_image }
  let!(:mission3) { create :mission, name: 'test3', token_id: token.id, image: mission_dummy_image }
  let!(:mission4) { create :mission, name: 'test4', token_id: token.id, image: mission_dummy_image }
  let!(:mission5) { create :mission, name: 'test5', token_id: token.id, image: mission_dummy_image }
  let!(:project) { create :project, title: 'default project 8344', mission_id: mission1.id, visibility: 'public_listed' }
  let!(:project_featured) { create :project, title: 'featured project 9934', mission_id: mission1.id, visibility: 'public_listed', status: 0 }

  scenario '#featured' do
    stub_airtable
    account.project_roles.create(project_id: project_featured.id, protocol: 'Holo')
    login account

    visit root_path
    sleep 10
    save_page
    expect(find('.featured-missions')).to have_content 'featured project 9934'
    expect(find('.featured-missions')).not_to have_content 'default project 8344'

    expect(page).to have_content 'Unfollow'
    expect(page).to have_content 'test1'
    expect(page).to have_content 'test2'
    expect(page).to have_content 'test3'
    expect(page).to have_content 'test4'
    expect(page).to have_content 'test5'
  end
end
