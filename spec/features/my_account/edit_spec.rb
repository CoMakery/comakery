require 'rails_helper'

describe 'my account' do
  let!(:account) { create :account, email: 'test@test.st' }

  before do
    login account
    visit root_path
    first('.menu').click_link account.decorate.name
    expect(page).to have_content 'Account Details'

    within('.view-ethereum-wallet') do
      first(:link).click
    end
  end

  scenario 'edit account information failed', js: true do
    fill_in 'firstName', with: ''
    fill_in 'lastName', with: ''
    fill_in 'ethereumWallet', with: "0x#{'a' * 40}"
    # click_on 'Save'
    page.find('input[type=submit]').trigger(:click)

    expect(page).to have_content("First name can't be blank")
    expect(page).to have_content("Last name can't be blank")
  end

  scenario 'edit account information success', js: true do
    fill_in 'firstName', with: 'Tester'
    fill_in 'lastName', with: 'Dev'
    fill_in 'ethereumWallet', with: "0x#{'a' * 40}"
    fill_in 'qtumWallet', with: "Q#{'a' * 33}"
    fill_in 'cardanoWallet', with: "A#{'b' * 58}"
    # click_on 'Save'
    page.find('input[type=submit]').trigger(:click)

    expect(page).to have_content 'Your account details have been updated.'
    expect(page).to have_content 'Tester'
    expect(page).to have_content 'Dev'

    stub_token_symbol
    project = create(:project, ethereum_contract_address: '0x' + 'a' * 40)
    award_type = create :award_type, project: project
    award = create :award, award_type: award_type, account: account

    visit account_path
    expect(page).to have_content project.title
    award.update ethereum_transaction_address: '0x' + 'a' * 64
    expect(award.errors.full_messages).to eq []
    # visit account_path(history: true)
    # Now we dont have refresh -> instead we should click radio button on React component
    choose 'History'
    expect(page).to have_link award.decorate.ethereum_transaction_address_short
  end
end
