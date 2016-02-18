require "rails_helper"

describe ProjectsController do
  let!(:project) { create :project }

  before { login }

  describe "#index" do
    it "lists the projects" do
      get :index

      expect(response.status).to eq(200)
      expect(assigns[:projects].to_a).to eq([project])
    end
  end

  describe "#new" do
    it "works" do
      get :new

      expect(response.status).to eq(200)
      expect(assigns[:project]).to be_a_new_record
      expect(assigns[:project].reward_types.first).to be_a_new_record
    end
  end

  describe "#create" do
    it "creates a project" do
      expect do
        expect do
          post :create, project: {
                          title: "Project title here",
                          description: "Project description here",
                          tracker: "http://github.com/here/is/my/tracker",
                          reward_types_attributes: [
                              {name: "Small Reward", suggested_amount: 1000},
                              {name: "Big Reward", suggested_amount: 2000},
                          ]
                      }
          expect(response.status).to eq(302)
        end.to change { Project.count }.by(1)
      end.to change { RewardType.count }.by(2)

      project = Project.last
      expect(project.title).to eq("Project title here")
      expect(project.description).to eq("Project description here")
      expect(project.tracker).to eq("http://github.com/here/is/my/tracker")
      expect(project.reward_types.first.name).to eq("Small Reward")
    end
  end

  describe "#edit" do
    it "works" do
      project = create(:project)

      get :edit, id: project.to_param

      expect(response.status).to eq(200)
      expect(assigns[:project]).to eq(project)
    end
  end

  describe "#update" do
    it "updates a project" do
      project = create(:project)
      small_reward_type = project.reward_types.create!(name: "Small Reward", suggested_amount: 100)
      medium_reward_type = project.reward_types.create!(name: "Medium Reward", suggested_amount: 300)

      expect do
        expect do
          put :update, id: project.to_param,
              project: {
                  title: "updated Project title here",
                  description: "updated Project description here",
                  tracker: "http://github.com/here/is/my/tracker/updated",
                  reward_types_attributes: [
                      {id: small_reward_type.to_param, name: "Small Reward", suggested_amount: 150},
                      {name: "Big Reward", suggested_amount: 500},
                  ]
              }
          expect(response.status).to eq(302)
        end.to change { Project.count }.by(0)
      end.to change { RewardType.count }.by(1)

      expect(flash[:notice]).to eq("Project updated")
      project.reload
      expect(project.title).to eq("updated Project title here")
      expect(project.description).to eq("updated Project description here")
      expect(project.tracker).to eq("http://github.com/here/is/my/tracker/updated")

      reward_types = project.reward_types.order(:suggested_amount)
      expect(reward_types.size).to eq(3)
      expect(reward_types.first.name).to eq("Small Reward")
      expect(reward_types.first.suggested_amount).to eq(150)
      expect(reward_types.second.name).to eq("Medium Reward")
      expect(reward_types.second.suggested_amount).to eq(300)
      expect(reward_types.third.name).to eq("Big Reward")
      expect(reward_types.third.suggested_amount).to eq(500)
    end
  end

  describe "#show" do
    specify do
      get :show, id: project.to_param

      expect(response.code).to eq "200"
      expect(assigns(:project)).to eq project
    end
  end
end
