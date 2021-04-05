require 'rails_helper'

describe 'reset password' do
  let!(:account) { create :account, email: 'test@test.st', password: '12345678' }

  scenario 'send reset password request' do
    visit new_session_path
    click_link 'Forgot Password?'
    fill_in 'email', with: 'invalid@test.st'
    click_on 'Reset my password!'
    expect(page).to have_content 'Could not found account with given email'
    fill_in 'email', with: 'test@test.st'
    click_on 'Reset my password!'
    expect(page).to have_content 'Please check your email for reset password instructions'
    expect(page.current_url).to have_content '/password_resets/new'
  end

  scenario 'update password' do
    account.update reset_password_token: '12345'
    visit edit_password_reset_path('invalidtoken')
    expect(page).to have_content 'Invalid reset password token'
    visit edit_password_reset_path('12345')
    expect(page).to have_content 'Set a password'
    fill_in 'account[password]', with: '12345678'
    click_on 'Save'
    expect(page).to have_content 'Successful reset password'
  end
end
