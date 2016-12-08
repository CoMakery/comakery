require "rails_helper"

describe "viewing projects, creating and editing", :js do
  let!(:project) { create(:project, title: "Cats with Lazers Project", description: "cats with lazers", owner_account: account, slack_team_id: "citizencode", public: false) }
  let!(:public_project) { create(:project, title: "Public Project", description: "dogs with donuts", owner_account: account, slack_team_id: "citizencode", public: true) }
  let!(:public_project_award_type) { create(:award_type, project: public_project) }
  let!(:public_project_award) { create(:award, award_type: public_project_award_type, created_at: Date.new(2016, 1, 9)) }
  let!(:account) { create(:account, email: "gleenn@example.com").tap { |a| create(:authentication, account_id: a.id, slack_team_id: "citizencode", slack_team_domain: "citizencodedomain", slack_team_name: "Citizen Code", slack_team_image_34_url: "https://slack.example.com/awesome-team-image-34-px.jpg", slack_team_image_132_url: "https://slack.example.com/awesome-team-image-132-px.jpg", slack_user_name: 'gleenn', slack_first_name: "Glenn", slack_last_name: "Spanky") } }
  let!(:same_team_account) { create(:account, ethereum_wallet: "0x#{'1'*40}") }
  let!(:same_team_account_authentication) { create(:authentication, account: same_team_account, slack_team_id: "citizencode", slack_team_name: "Citizen Code") }
  let!(:other_team_account) { create(:account).tap { |a| create(:authentication, account_id: a.id, slack_team_id: "comakery", slack_team_name: "CoMakery") } }
  let(:bobjohnsons_auth) { Authentication.find_by(slack_user_name: "bobjohnson") }

  before do
    Rails.application.config.allow_ethereum = 'citizencodedomain'
    travel_to Date.new(2016, 1, 10)
    stub_slack_user_list
    stub_slack_channel_list

    travel_to(DateTime.parse("Mon, 29 Feb 2016 00:00:00 +0000"))  # so we can check for fixed date of award

    expect_any_instance_of(Account).to receive(:send_award_notifications)
    stub_slack_user_list([{"id": "U99M9QYFQ", "team_id": "team id", "name": "bobjohnson", "profile": {"email": "bobjohnson@example.com"}}])
    stub_request(:post, "https://slack.com/api/users.info").to_return(body: {
        ok: true,
        "user": {
            "id": "U99M9QYFQ",
            "team_id": "team id",
            "name": "bobjohnson",
            "profile": {
                email: "bobjohnson@example.com"
            }
        }
    }.to_json)
  end

  after do
    travel_back
  end

  it "setup royalties project with USD" do
    login(account)

    visit projects_path

    click_link "New Project"
    fill_in "Title", with: "Mindfulness App"
    select "Royalties paid in US Dollars ($)", from: "Award Payment Type"
    fill_in "Maximum Awards", with: "100000"
    fill_in "Description", with: "This is a project"
    select "a-channel-name", from: "Slack Channel"

    click_on "Save"
    expect(page).to have_content "Project created"
    expect(page).to have_content "$100,000 max"
    expect(page).to have_content "$0 total"
    expect(page).to have_content "$0 mine"
    within(".award-header") { expect(page).to have_content /royalties/i }
    within(".award-send") { expect(page).to have_content /award royalties/i }
    select "@bobjohnson", from: "User"
    choose "Small"
    fill_in "Description", with: "Super fantastic fabulous programatic work on teh things, A++"

    click_button "Send"
    within('.award-rows') { expect(page).to have_content "@bobjohnson $100 $0 $100" }

    click_link "History"
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "$100"

    login(bobjohnsons_auth.account)
    visit account_path
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "$100"
  end

  it "setup royalties project with BTC" do
    login(account)

    visit projects_path

    click_link "New Project"
    fill_in "Title", with: "Mindfulness App"
    select "Royalties paid in Bitcoin (฿)", from: "Award Payment Type"
    fill_in "Maximum Awards", with: "100000"
    fill_in "Description", with: "This is a project"
    select "a-channel-name", from: "Slack Channel"

    click_on "Save"
    expect(page).to have_content "Project created"
    expect(page).to have_content "฿100,000 max"
    expect(page).to have_content "฿0 total"
    expect(page).to have_content "฿0 mine"
    within(".award-header") { expect(page).to have_content /royalties/i }
    within(".award-send") { expect(page).to have_content /award royalties/i }
    select "@bobjohnson", from: "User"
    choose "Small"
    fill_in "Description", with: "Super fantastic fabulous programatic work on teh things, A++"

    click_button "Send"
    within('.award-rows') { expect(page).to have_content "@bobjohnson ฿100 ฿0 ฿100" }

    click_link "History"
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "฿100"

    login(bobjohnsons_auth.account)
    visit account_path
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "฿100"
  end

  xit "setup royalties project with ETH" do
    login(account)

    visit projects_path

    click_link "New Project"
    fill_in "Title", with: "Mindfulness App"
    select "Royalties paid in Ether (Ξ)", from: "Award Payment Type"
    fill_in "Maximum Awards", with: "100000"
    fill_in "Description", with: "This is a project"
    select "a-channel-name", from: "Slack Channel"

    click_on "Save"
    expect(page).to have_content "Project created"
    expect(page).to have_content "Ξ100,000 max"
    expect(page).to have_content "Ξ0 total"
    expect(page).to have_content "Ξ0 mine"
    within(".award-header") { expect(page).to have_content /royalties/i }
    within(".award-send") { expect(page).to have_content /award royalties/i }
    select "@bobjohnson", from: "User"
    choose "Small"
    fill_in "Description", with: "Super fantastic fabulous programatic work on teh things, A++"

    click_button "Send"
    within('.award-rows') { expect(page).to have_content "@bobjohnson Ξ100 Ξ0 Ξ100" }

    click_link "History"
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "Ξ100"

    login(bobjohnsons_auth.account)
    visit account_path
    within(".header-row") { expect(page).to have_content /Royalties Earned/i }
    expect(page).to have_content "Ξ100"
  end

  it "setup project with Project Coins" do
    login(account)

    visit projects_path

    click_link "New Project"
    fill_in "Title", with: "Mindfulness App"
    select "Project Coin direct payment", from: "Award Payment Type"
    fill_in "Maximum Awards", with: "100000"
    fill_in "Description", with: "This is a project"
    select "a-channel-name", from: "Slack Channel"

    click_on "Save"
    expect(page).to have_content "Project created"
    expect(page).to have_content "100,000 max"
    expect(page).to have_content "0 total"
    expect(page).to have_content "0 mine"
    within(".award-header") { expect(page).to have_content /project coins/i }
    within(".award-send") { expect(page).to have_content /award project coins/i }
    select "@bobjohnson", from: "User"
    choose "Small"
    fill_in "Description", with: "Super fantastic fabulous programatic work on teh things, A++"

    click_button "Send"
    within('.award-rows') { expect(page).to have_content "@bobjohnson 100 0 100" }

    click_link "History"
    within(".header-row") { expect(page).to have_content /Project Coins Earned/i }
    expect(page).to have_content "100"

    login(bobjohnsons_auth.account)
    visit account_path
    within(".header-row") { expect(page).to have_content /Project Coins Earned/i }
    expect(page).to have_content "100"
  end
end
