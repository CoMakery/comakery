require 'rails_helper'
require 'refile/file_double'

feature 'pages' do
  scenario '#user_agreement' do
    visit user_agreement_path
    expect(page).to have_content 'User Agreement'
  end

  scenario '#prohibited_use' do
    visit prohibited_use_path
    expect(page).to have_content 'Prohibited Use'
  end

  scenario '#e_sign_disclosure' do
    visit e_sign_disclosure_path
    expect(page).to have_content 'E-SIGN DISCLOSURE'
  end

  scenario '#privacy_policy' do
    visit privacy_policy_path
    expect(page).to have_content 'Privacy Policy'
  end

  scenario '#contribution_licenses' do
    visit contribution_licenses_path('CP')
    expect(page).to have_content 'Contribution License'
  end
end
