require 'rails_helper'

feature "my account" do
  let!(:project) { create(:sb_project, ethereum_enabled: true) }
  let!(:auth) { create(:sb_authentication) }
  let!(:issuer) { create(:sb_authentication, slack_user_name: "John Collins") }
  let!(:award_type) { create(:award_type, project: project, amount: 1337) }
  let!(:award1) { create(:award, award_type: award_type, authentication: auth,
    issuer: issuer.account, created_at: Date.new(2016, 3, 25)) }
  let!(:award2) { create(:award, award_type: award_type, authentication: auth,
    issuer: issuer.account, created_at: Date.new(2016, 3, 25)) }

  scenario "viewing" do
    visit root_path
    expect(page).not_to have_content "Account"
    login(auth.account)

    visit root_path
    first('.menu').click_link "Account"

    expect(page).to have_content "Swarmbot"
    expect(page).to have_content "1,337"
    expect(page).to have_content "Mar 25, 2016"
    expect(page).to have_content "Contribution"
    expect(page).to have_content "Great work"
    expect(page).to have_content "John Doe"
  end

  scenario "editing, and adding an ethereum address" do
    login(auth.account)
    visit root_path
    first('.menu').click_link "Account"

    within(".ethereum_wallet") do
      click_link "Edit"
      click_link "Cancel"

      click_link "Edit"
      fill_in "Ethereum Address", with: "too short and with spaces"
      click_on "Save"
    end

    expect(page).to have_content "Ethereum wallet should start with '0x',
      followed by a 40 character ethereum address"

    within(".ethereum_wallet") do
      fill_in "Ethereum Address", with: "0x#{'a'*40}"
      click_on "Save"
    end

    expect(page).to have_content "Ethereum account updated"
    expect(page).to have_content "0x#{'a'*40}"
  end

  scenario 'adding an ethereum address sends ethereum tokens, for awards' do
    login(auth.account)
    visit root_path
    first('.menu').click_link "Account"

    within(".ethereum_wallet") do
      click_link "Edit"
      fill_in "Ethereum Address", with: "0x#{'a'*40}"
      click_on "Save"
    end

    expect(EthereumTokenIssueJob.jobs.map{|job| job['args']}.flatten).to \
      match_array([award2.id, award1.id])
  end
end
