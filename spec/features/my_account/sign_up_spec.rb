require 'rails_helper'

describe 'my account', js: true do
  let!(:unconfirmed_account) { create :account, nickname: 'jason', email_confirm_token: '0' }
  let!(:to_be_confirmed_account) { create :account, nickname: 'jason', email_confirm_token: '1' }
  let!(:confirmed_account) { create :account, nickname: 'jason', email_confirm_token: nil }

  scenario 'user gets redirected to survey page after signup' do
    visit root_path
    first('.header--nav--links').click_link 'Sign Up'
    click_on 'CREATE YOUR ACCOUNT'
    expect(page).to have_content("can't be blank", count: 4)
    fill_in 'account[email]', with: 'test@test.st'
    fill_in 'First Name', with: 'Tester'
    fill_in 'Last Name', with: 'Dev'
    fill_in 'Date of Birth', with: '01/01/2000'
    click_on 'CREATE YOUR ACCOUNT'
    fill_in 'Password', with: '12345678'
    page.check('account_agreed_to_user_agreement')
    click_on 'CREATE YOUR ACCOUNT'
    expect(Account.last&.decorate&.name).to eq 'Tester Dev'
    expect(page).to have_content(/Sign out/i)
    expect(page).to have_content('FILL OUT THE SHORT FORM BELOW TO GET STARTED')
    expect(page).not_to have_content('Please confirm your email before continuing.')
  end

  scenario 'featured page is available after signup' do
    login(unconfirmed_account)
    visit '/featured'
    expect(page.current_url).to have_content '/featured'
    expect(page).to have_content('Please confirm your email before continuing.')
    stub_airtable
    click_on "I'M INTERESTED!", match: :first
    wait_for_ajax
    expect(unconfirmed_account.interests.count).to be > 0
    expect(page).to have_content('INTEREST, NOTED!')
  end

  scenario 'account page is available after signup' do
    login(unconfirmed_account)
    visit '/account'
    expect(page.current_url).to have_content '/account'
    expect(page).not_to have_content('Please confirm your email before continuing.')
  end

  scenario 'projects page is unavailable after signup' do
    login(unconfirmed_account)
    visit '/projects'
    expect(page.current_url).to have_content /\/$/
    expect(page).to have_content('Please confirm your email before continuing.')
  end

  scenario 'my projects page is unavailable after signup' do
    login(unconfirmed_account)
    visit '/projects/mine'
    expect(page.current_url).to have_content /\/$/
    expect(page).to have_content('Please confirm your email before continuing.')
  end

  scenario 'account gets confirmed after visiting confirmation link' do
    visit "/accounts/confirm/#{to_be_confirmed_account.email_confirm_token}"
    expect(page).to have_content('Success! Your email is confirmed.')
    expect(page).to have_content(/Sign out/i)
  end

  scenario 'projects page is available after email confirmation' do
    login(confirmed_account)
    visit '/projects'
    expect(page.current_url).to have_content '/projects'
    expect(page).not_to have_content('Please confirm your email before continuing.')
  end

  scenario 'my projects page is available after email confirmation' do
    login(confirmed_account)
    visit '/projects/mine'
    expect(page.current_url).to have_content '/projects/mine'
    expect(page).not_to have_content('Please confirm your email before continuing.')
  end
end
