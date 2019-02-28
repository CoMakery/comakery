require 'rails_helper'

describe 'my account', js: true do
  let!(:unconfirmed_account) { create :account, nickname: 'jason', email_confirm_token: '0' }
  let!(:to_be_confirmed_account) { create :account, nickname: 'jason', email_confirm_token: '1' }
  let!(:confirmed_account) { create :account, nickname: 'jason', email_confirm_token: nil }
  let!(:token) { create :token }
  let!(:mission) { create :mission, token_id: token.id }
  let!(:project) { create :project, mission_id: mission.id, visibility: 'public_listed', status: 0 }

  scenario 'user gets redirected to signup on create project click' do
    visit '/'
    expect(page.current_url).to have_content '/'
    expect(page).to have_content('CoMakery Hosts Blockchain Missions We Believe In')
    stub_airtable
    find('a.featured-mission__create-project').click
    sleep 2
    expect(page.current_url).to have_content '/accounts/new'
  end

  scenario 'user gets redirected to signup on interest click' do
    visit '/'
    expect(page.current_url).to have_content '/'
    expect(page).to have_content('CoMakery Hosts Blockchain Missions We Believe In')
    stub_airtable
    find('.featured-mission__project__interest').click
    sleep 2
    expect(page.current_url).to have_content '/accounts/new'
  end

  scenario 'user gets redirected to build profile page after signup' do
    visit root_path
    first('.header--nav--links').click_link 'Sign Up'
    click_on 'CREATE YOUR ACCOUNT'
    expect(page).to have_content("can't be blank", count: 1)
    fill_in 'account[email]', with: 'test@test.st'
    fill_in 'Password', with: '12345678'
    page.check('account_agreed_to_user_agreement')
    click_on 'CREATE YOUR ACCOUNT'
    expect(page).to have_content('Build Your Profile')
  end

  scenario 'show email input field if email is empty' do
    # rubocop:disable SkipsModelValidations
    confirmed_account.update_column('email', nil)
    login(confirmed_account)
    visit build_profile_accounts_path
    expect(page).to have_content('E-mail: *')
  end

  scenario 'Sign up flow with metamask' do
    metamask_account = Account.new(email: nil, public_address: '0xtest_address', nonce: 'test_nonce')
    metamask_account.save(validate: false)
    login(metamask_account)
    visit build_profile_accounts_path
    expect(page).not_to have_content("can't be blank")
    click_on 'SAVE YOUR PROFILE'
    expect(page).to have_content("Email can't be blank, Email is invalid")
  end

  scenario 'featured page is available after signup' do
    login(confirmed_account)
    open(Rails.root.join('spec', 'fixtures', 'helmet_cat.png'), 'rb') do |file|
      mission.image = file
    end
    mission.save

    visit '/'
    expect(page.current_url).to have_content '/'
    expect(page).to have_content('CoMakery Hosts Blockchain Missions We Believe In')
    stub_airtable
    find('.featured-mission__project__interest').click
    sleep 2
    expect(confirmed_account.interests.count).to be > 0
    expect(page).to have_content('REQUEST SENT')
  end

  scenario 'account page is available after signup' do
    login(unconfirmed_account)
    visit '/account'
    expect(page.current_url).to have_content '/account'
    expect(page).not_to have_content('Please confirm your email address to continue')
  end

  scenario 'projects page is unavailable after signup' do
    login(unconfirmed_account)
    visit '/projects'
    expect(page).to have_current_path(root_path)
    expect(page).to have_content('PLEASE CONFIRM YOUR EMAIL ADDRESS TO CONTINUE')
  end

  scenario 'my projects page is unavailable after signup' do
    login(unconfirmed_account)
    visit '/projects/mine'
    expect(page).to have_current_path(root_path)
    expect(page).to have_content('PLEASE CONFIRM YOUR EMAIL ADDRESS TO CONTINUE')
  end

  scenario 'account gets confirmed after visiting confirmation link' do
    visit "/accounts/confirm/#{to_be_confirmed_account.email_confirm_token}"
    expect(page).to have_current_path(root_path)
    # we don't have notification inside react pages
    # expect(page).to have_content 'Success! Your email is confirmed.'
    expect(page).to have_content(/Sign out/i)
  end

  scenario 'projects page is available after email confirmation' do
    login(confirmed_account)
    visit '/projects'
    expect(page.current_url).to have_content '/projects'
    expect(page).not_to have_content('Please confirm your email address to continue')
  end

  scenario 'my projects page is available after email confirmation' do
    login(confirmed_account)
    visit '/projects/mine'
    expect(page.current_url).to have_content '/projects/mine'
    expect(page).not_to have_content('Please confirm your email address to continue')
  end
end
