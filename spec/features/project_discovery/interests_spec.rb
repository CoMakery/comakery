require 'rails_helper'

describe 'interests', js: true do
  let!(:account) { create :account }
  let!(:mission) { create :mission }
  let!(:project) { create :project, mission: mission, visibility: 'public_listed', status: 0 }

  before do
    login account
    page.driver.browser.manage.add_cookie(name: 'cookieconsent_status', value: 'dismiss')
  end

  context 'on project landing page' do
    it 'has follow button for the project' do
      visit project_path(project)

      expect(page).to have_content 'FOLLOW'
      first('button.project-interest__button').click
      expect(page).to have_content 'UNFOLLOW'
      first('button.project-interest__button').click
      expect(page).to have_content 'FOLLOW'
    end
  end

  context 'on mission page' do
    it 'has follow buttons for featured projects' do
      visit mission_path(mission)
      scroll_to(:bottom)

      expect(page).to have_content 'FOLLOW'
      first('.mission-projects__single__card__info__interest__link').click
      expect(page).to have_content 'UNFOLLOW'
      first('.mission-projects__single__card__info__interest__link').click
      expect(page).to have_content 'FOLLOW'
    end
  end
end
