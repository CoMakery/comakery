require "rails_helper"

def get_award_type_rows
  page.all(".award-type-row")
end

def click_remove(award_type_row)
  award_type_row.find("a[data-mark-and-hide]").click
end

describe "viewing projects, creating and editing", :js, :vcr do
  let!(:project) { create(:project, title: "Project 1", description: "cats with lazers", owner_account: account, slack_team_id: "citizencode", public: false) }
  let!(:project2) { create(:project, title: "Public Project", owner_account: account, slack_team_id: "citizencode", public: true) }
  let!(:account) { create(:account, email: "gleenn@example.com").tap { |a| create(:authentication, account_id: a.id, slack_team_id: "citizencode", slack_team_name: "Citizen Code", slack_user_name: 'gleenn', slack_first_name: "Glenn", slack_last_name: "Spanky", slack_team_domain: "citizencodedomain") } }
  let!(:same_team_account) { create(:account).tap { |a| create(:authentication, account_id: a.id, slack_team_id: "citizencode", slack_team_name: "Citizen Code") } }
  let!(:other_team_account) { create(:account).tap { |a| create(:authentication, account_id: a.id, slack_team_id: "comakery", slack_team_name: "CoMakery") } }

  describe "while logged out" do
    it "allows viewing public projects index and show" do
      visit root_path

      expect(page).not_to have_content "My Projects"

      expect(page).not_to have_content "Project 1"
      expect(page).to have_content "Public Project"

      expect(page).not_to have_content "New Project"

      click_link "Public Project"

      expect(page).to have_current_path(project_path(project2))

      expect(page).to have_content "Public Project"
      expect(page).to have_content "Visibility: Public"
      expect(page).to have_content "Team name: Citizen Code"
    end
  end

  describe "landing and searching" do
    it "shows some projects" do
      login(account)

      7.times { |i| create(:project, title: "Public Project #{i}", public: true, slack_team_name: "This is a slack team name") }
      7.times { |i| create(:project, title: "Private Project #{i}", public: false, slack_team_id: "citizencode", slack_team_name: "This is a slack team name") }

      visit root_path

      expect(page.all(".project").size).to eq(12)
      expect(page).to have_content "Public Project"
      expect(page).to have_content "This is a slack team name"

      click_link "Browse All"

      expect(page.all(".project").size).to eq(16)
      expect(page).to have_content "Public Project"
    end
  end

  describe "removing award types on projects where there have been awards sent already" do
    it "prevents destroying the award types" do
      login(account)

      award_type = create(:award_type, project: project, name: "Big ol' award", amount: 40000)

      visit edit_project_path(project)

      expect(page.all("a[data-mark-and-hide]").size).to eq(1)

      create(:award, award_type: award_type, account: same_team_account)

      visit edit_project_path(project)

      expect(page.all("a[data-mark-and-hide]").size).to eq(0)
      expect(page).to have_content "(1 award sent)"
    end
  end

  it "does the happy path" do
    stub_request(:post, /slack\.com/).to_return(body: '{"ok": true, "members": []}')

    login(account)

    visit projects_path

    expect(page).to have_content "Project 1"

    within "#project-#{project.to_param}" do
      click_link project.title
    end

    click_link "Back"

    click_link "New Project"

    fill_in "Description", with: "This is a project description which is very informative"
    attach_file "Project Image", Rails.root.join("spec", "fixtures", "helmet_cat.png")
    expect(find_field("Set project as public (display in CoMakery index)")).to be_checked

    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(3)
    award_type_inputs[0].all("input")[0].set "This is a small award type"
    award_type_inputs[0].all("input")[1].set "1000"
    award_type_inputs[1].all("input")[0].set "This is a medium award type"
    award_type_inputs[1].all("input")[1].set "2000"
    award_type_inputs[2].all("input")[0].set "This is a large award type"
    award_type_inputs[2].all("input")[1].set "3000"
    # award_type_inputs[3]["class"].include?("hide")

    click_link "+ add award type"

    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(4)

    award_type_inputs[3].all("input")[0].set "This is a super big award type"
    award_type_inputs[3].all("input")[1].set "5000"

    click_link "+ add award type"

    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(5)

    click_remove(award_type_inputs.last)

    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(4)

    click_on "Save"

    expect(page).to have_content "Title can't be blank"

    fill_in "Title", with: "This is a project"

    click_on "Save"

    expect(page).to have_content "Project created"
    expect(page).to have_content "This is a project"
    expect(page).to have_content "This is a project description which is very informative"
    expect(page.find(".project-image")[:src]).to match(/\/attachments\/[A-Za-z0-9\/]+\/image/)
    expect(page).not_to have_link "Project Tasks"
    expect(page).to have_content "Visibility: Public"

    expect(page).to have_content "Owner: Glenn Spanky"
    expect(page).to have_content "Team name: Citizen Code"

    award_type_rows = page.all(".award-type-row")
    expect(award_type_rows.size).to eq(4)

    expect(award_type_rows[0]).to have_content "This is a small award type"
    expect(award_type_rows[0]).to have_content "1000"

    expect(award_type_rows[1]).to have_content "This is a medium award type"
    expect(award_type_rows[1]).to have_content "2000"

    expect(award_type_rows[2]).to have_content "This is a large award type"
    expect(award_type_rows[2]).to have_content "3000"

    expect(award_type_rows[3]).to have_content "This is a super big award type"
    expect(award_type_rows[3]).to have_content "5000"

    click_on "Edit"

    expect(page.find(".project-image")[:src]).to match(/\/attachments\/[A-Za-z0-9\/]+\/image/)

    expect(page).to have_checked_field("Set project as public (display in CoMakery index)")
    fill_in "Title", with: "This is an edited project"
    fill_in "Description", with: "This is an edited project description which is very informative"
    fill_in "Project Tracker", with: "http://github.com/here/is/my/tracker"
    uncheck "Set project as public (display in CoMakery index)"

    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(4)

    award_type_inputs[0].all("a[data-mark-and-hide]")[0].click
    award_type_inputs = get_award_type_rows
    expect(award_type_inputs.size).to eq(3)

    click_on "Save"

    expect(page).to have_content "Project updated"
    expect(page).to have_content "This is an edited project"
    expect(page).to have_content "This is an edited project description which is very informative"
    expect(page).to have_content "Visibility: Private"
    expect(page).to have_link "Project Tasks"
    expect(page).to have_link "Project Slack Channel", href:"https://citizencodedomain.slack.com"

    award_type_inputs = page.all(".award-type-row")
    expect(award_type_inputs.size).to eq(3)
    expect(page).not_to have_content "This is a small award type"
    expect(page).not_to have_content "1000"

    expect(award_type_inputs.size).to eq(3)

    visit("/projects")

    expect(page).to have_content "This is an edited project"

    login(same_team_account)

    visit("/projects")

    expect(page).to have_content "This is an edited project"

    login(other_team_account)

    visit("/projects")

    expect(page).not_to have_content "This is an edited project"

    expect(page).to have_content "Public Project"

    click_link "Public Project"

    expect(page).not_to have_content "Edit"
  end
end
