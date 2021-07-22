require 'rails_helper'

describe 'my account', js: true do
  let!(:unconfirmed_account) { create :account, email_confirm_token: '0' }
  let!(:to_be_confirmed_account) { create :account, email_confirm_token: '1' }
  let!(:confirmed_account) { create :account, email_confirm_token: nil }
  let!(:token) { create :token }
  let!(:mission) { create :mission, token_id: token.id }
  let!(:project) { create :project, mission_id: mission.id, visibility: 'public_listed', status: 0 }
  let!(:project_member) { create(:project) }

  scenario 'user gets redirected to sign in when accessing My Tasks' do
    visit '/tasks'
    expect(page.current_url).to include('/session/new')
  end

  scenario 'logged out user can see Taks Details for a public project' do
    logout
    award = create(:award)
    award.project.member!
    award.project.save!
    login(award.project.account)
    url = "/projects/#{award.project.id}/batches/#{award.award_type.id}/tasks/#{award.id}"
    visit url
    expect(page.current_url).to include(url)
    expect(page).to have_content('TASK DETAILS')
  end

  scenario 'user gets redirected to root when accessing Batches for a private project' do
    visit project_award_types_path(project_member)
    expect(page.current_path).to eq('/')
  end

  scenario 'user gets redirected to sign in when accessing My Account' do
    visit '/account'
    expect(page.current_url).to include('/session/new')
  end

  scenario 'user gets redirected to build profile page after signup' do
    visit root_path
    first('.header--nav--links').click_link 'Sign Up'
    click_on 'Create Your Account'
    expect(page).to have_content("can't be blank", count: 1)
    fill_in 'account[email]', with: 'test@test.st'
    fill_in 'Password', with: '12345678'
    page.check('account_agreed_to_user_agreement')
    click_on 'Create Your Account'
    expect(page).to have_content('Setup Your Account')
  end

  scenario 'Sign up flow with metamask' do
    metamask_account = Account.new(email: nil, public_address: '0xtest_address', nonce: 'test_nonce')
    metamask_account.save(validate: false)
    login(metamask_account)
    visit build_profile_accounts_path
    expect(page).not_to have_content("can't be blank")
    click_on 'Get Started'
    expect(page).to have_content("Email can't be blank")
  end

  scenario 'MetaMask button disabled' do
    visit new_account_path
    expect(page).not_to have_selector 'button', text: 'MetaMask', exact_text: true
  end

  scenario 'MetaMask button enabled' do
    stub_const('ENV', ENV.to_hash.merge('METAMASK_LOGIN' => 'true'))
    visit new_account_path
    expect(page).to have_selector 'button', text: 'MetaMask', exact_text: true
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
    expect(page).to have_current_path(show_account_path)
    expect(page).to have_content('Please confirm your email address to continue')
  end

  scenario 'my projects page is unavailable after signup' do
    login(unconfirmed_account)
    visit '/projects/mine'
    expect(page).to have_current_path(show_account_path)
    expect(page).to have_content('Please confirm your email address to continue')
  end

  scenario 'account gets confirmed after visiting confirmation link' do
    visit "/accounts/confirm/#{to_be_confirmed_account.email_confirm_token}"
    expect(page).to have_current_path(my_tasks_path)
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
