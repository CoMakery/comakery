require 'rails_helper'

describe ProjectPolicy do
  let!(:account) { create(:account).tap{|a| create(:authentication, account: a, slack_team_id: "citizen code id")} }
  let!(:my_public_project) { create(:project, title: "public mine", owner_account: account, public: true, slack_team_id: "citizen code id") }
  let!(:my_private_project) { create(:project, title: "private mine", owner_account: account, public: false, slack_team_id: "citizen code id") }

  let!(:other_team_member) { create(:account).tap{|a| create(:authentication, account: a, slack_team_id: "citizen code id")} }
  let!(:others_public_project) { create(:project, title: "public someone elses", owner_account: other_team_member, public: true, slack_team_id: "citizen code id") }
  let!(:others_private_project) { create(:project, title: "private someone elses", owner_account: other_team_member, public: false, slack_team_id: "citizen code id") }

  let!(:different_team_account) { create(:account).tap{|a| create(:authentication, account: a, slack_team_id: "comakery id")} }

  describe ProjectPolicy::Scope do
    describe "#resolve" do
      it "returns all public projects and projects that belong to the current user's team" do
        projects = ProjectPolicy::Scope.new(account, Project).resolve

        expect(projects.map(&:title).sort).to eq([my_private_project, others_private_project, my_public_project, others_public_project].map(&:title))
      end

      it "returns all public projects if account is nil" do
        projects = ProjectPolicy::Scope.new(nil, Project).resolve

        expect(projects.map(&:title).sort).to eq([my_public_project, others_public_project].map(&:title))
      end
    end
  end

  describe "#award?" do
    it "returns true if an account is the owner of a project and false otherwise" do
      expect(ProjectPolicy.new(nil, my_public_project).send_award?).to be false
      expect(ProjectPolicy.new(nil, my_private_project).send_award?).to be false

      expect(ProjectPolicy.new(account, my_public_project).send_award?).to be true
      expect(ProjectPolicy.new(account, my_private_project).send_award?).to be true

      expect(ProjectPolicy.new(other_team_member, my_public_project).send_award?).to be false
      expect(ProjectPolicy.new(other_team_member, my_private_project).send_award?).to be false

      expect(ProjectPolicy.new(different_team_account, my_public_project).send_award?).to be false
      expect(ProjectPolicy.new(different_team_account, my_private_project).send_award?).to be false
    end
  end

  describe "#show?" do
    it "allows viewing of projects that are public or are owned by the current account" do
      expect(ProjectPolicy.new(nil, my_public_project).show?).to be true
      expect(ProjectPolicy.new(nil, others_private_project).show?).to be false

      expect(ProjectPolicy.new(account, my_public_project).show?).to be true
      expect(ProjectPolicy.new(account, my_private_project).show?).to be true
      expect(ProjectPolicy.new(account, others_private_project).show?).to be true

      expect(ProjectPolicy.new(other_team_member, others_public_project).show?).to be true
      expect(ProjectPolicy.new(other_team_member, my_private_project).show?).to be true

      expect(ProjectPolicy.new(different_team_account, my_public_project).show?).to be true
      expect(ProjectPolicy.new(different_team_account, my_private_project).show?).to be false
    end
  end

  describe "#edit? #update?" do
    it "only allows viewing of projects that are public or are owned by the current account" do
      [:edit?, :update?].each do |action|
        expect(ProjectPolicy.new(nil, my_public_project).send(action)).to be false
        expect(ProjectPolicy.new(nil, others_private_project).send(action)).to be false

        expect(ProjectPolicy.new(account, my_public_project).send(action)).to be true
        expect(ProjectPolicy.new(account, my_private_project).send(action)).to be true

        expect(ProjectPolicy.new(account, others_public_project).send(action)).to be false
        expect(ProjectPolicy.new(account, others_private_project).send(action)).to be false

        expect(ProjectPolicy.new(other_team_member, my_public_project).send(action)).to be false
        expect(ProjectPolicy.new(other_team_member, my_private_project).send(action)).to be false
      end

      expect(ProjectPolicy.new(different_team_account, my_public_project).edit?).to be false
      expect(ProjectPolicy.new(different_team_account, my_private_project).edit?).to be false
      expect(ProjectPolicy.new(different_team_account, my_public_project).update?).to be false
      expect(ProjectPolicy.new(different_team_account, my_private_project).update?).to be false
    end
  end
end
