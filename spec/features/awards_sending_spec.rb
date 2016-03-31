require 'rails_helper'

describe "awarding users" do
  let!(:project) { create(:project, title: "Project that needs awards", owner_account: owner_account, slack_team_id: "team id") }
  let!(:same_team_project) { create(:project, title: "Same Team Project", owner_account: owner_account, slack_team_id: "team id") }
  let!(:different_team_project) { create(:project, public: true, title: "Different Team Project", owner_account: owner_account, slack_team_id: "team id") }

  let!(:small_award_type) { create(:award_type, project: project, name: "Small", amount: 1000) }
  let!(:large_award_type) { create(:award_type, project: project, name: "Large", amount: 3000) }

  let!(:same_team_small_award_type) { create(:award_type, project: same_team_project, name: "Small", amount: 10) }
  let!(:same_team_small_award) { create(:award, authentication: owner_authentication, award_type: same_team_small_award_type) }

  let!(:different_large_award_type) { create(:award_type, project: different_team_project, name: "Large", amount: 3000) }
  let!(:different_large_award) { create(:award, award_type: different_large_award_type, authentication: different_team_authentication) }

  let!(:owner_account) { create(:account, email: "hubert@example.com") }
  let!(:other_account) { create(:account, email: "sherman@example.com") }
  let!(:different_team_account) { create(:account, email: "different@example.com") }

  let!(:owner_authentication) { create(:authentication, slack_user_name: 'hubert', slack_first_name: 'Hubert', slack_last_name: 'Sherbert', slack_user_id: 'hubert id', account: owner_account, slack_team_id: "team id", slack_team_image_34_url: "http://avatar.com/owner_team_avatar.jpg") }
  let!(:other_authentication) { create(:authentication, slack_user_name: 'sherman', slack_user_id: 'sherman id', slack_first_name: "Sherman", slack_last_name: "Yessir", account: other_account, slack_team_id: "team id", slack_image_32_url: "http://avatar.com/other_account_avatar.jpg") }
  let!(:different_team_authentication) { create(:authentication, slack_user_name: 'different', slack_user_id: 'different id', slack_first_name: "Different", slack_last_name: "Different", account: different_team_account, slack_team_id: "different team id", slack_image_32_url: "http://avatar.com/different_team_account_avatar.jpg") }

  before do
    travel_to(DateTime.parse("Mon, 29 Feb 2016 00:00:00 +0000"))

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

  describe "awarding a user which swarmbot doesn't have an account for yet" do
    it "populates the dropdown to select the awardee and creates the account/auth for the user" do
      login(owner_account)

      visit project_path(project)

      expect(page).to have_content "0My Project Coins"

      choose "Small"
      expect(page.all("select#award_slack_user_id option").map(&:text).sort).to eq(["", "@bobjohnson"])
      select "bobjohnson", from: "User"

      click_button "Send"

      expect(page).to have_content "Successfully sent award to @bobjohnson"

      bobjohnsons_auth = Authentication.find_by(slack_user_name: "bobjohnson")
      expect(bobjohnsons_auth).not_to be_nil

      login(bobjohnsons_auth.account)

      visit project_awards_path(bobjohnsons_auth.projects.first)

      expect(page).to have_content "@bobjohnson"

      click_link("Back to project")

      within(".coins-issued") do
        expect(page).to have_content "1,000My Project Coins"
        expect(page).to have_content "1,000/10,000,000 (0.01%)Total Coins Issued"
      end

      expect(page).to have_content "1,000@bobjohnson"

      expect(page.html).to include('{"content": [{"label":"@bobjohnson","value":1000}')
    end
  end

  it "has a working happy path" do
    login(other_account)

    visit root_path

    within(".project", text: "Project that needs awards") do
      click_link "Project that needs awards"
    end

    expect(page).to have_content("Project that needs awards")
    expect(page).not_to have_content("Send Award")
    expect(page).not_to have_content("User")

    login(owner_account)

    visit project_path(project)

    click_link "Award History"

    expect(page.all(".award-rows .award-row").size).to eq(0)

    expect(page).to have_content("Award History")

    click_link "Back to project"

    expect(page).to have_content("Project that needs awards")

    click_button "Send"

    expect(page).to have_content "Failed sending award"

    choose "Small"

    within(".award-types") do
      expect(page.all("input[type=radio]").size).to eq(2)
      expect(page.all("input[type=radio][disabled=disabled]").size).to eq(0)
    end

    expect(page.all("select#award_slack_user_id option").map(&:text).sort).to eq(["", "@bobjohnson"])
    select "@bobjohnson", from: "User"
    fill_in "Description", with: "Super fantastic fabulous programatic work on teh things, A++"

    click_button "Send"

    expect(page).to have_content "Successfully sent award to @bobjohnson"

    click_link "Award History"

    expect(page).to have_content "Award History"
    expect(page).to have_content "Feb 29"
    expect(page).to have_content "1,000"
    expect(page).to have_content "Small"
    expect(page).to have_content "Super fantastic fabulous programatic work on teh things, A++"
    expect(page).to have_content "@bobjohnson"

    expect(page.all(".award-rows .award-row").size).to eq(1)

    click_link "Back to project"

    expect(page).to have_content("Project that needs awards")

    visit landing_projects_path

    within(".project", text: "Project that needs awards") do
      expect(page.all("img.contributor").map { |img| img[:src] }).to match_array(["http://avatar.com/owner_team_avatar.jpg", "https://slack.example.com/team-image-34-px.jpg"])
    end
  end
end
