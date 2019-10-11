require 'rails_helper'

describe ProjectPolicy do
  let!(:team1) { create :team }
  let!(:team2) { create :team }
  let!(:project_account) { create :account }
  let!(:project_admin) { create :account }
  let!(:authentication) { create(:authentication, account: project_account) }

  let!(:my_public_project) { create(:project, title: 'public mine', account: project_account, visibility: 'public_listed') }
  let!(:my_public_unlisted_project) { create(:project, title: 'public mine', account: project_account, visibility: 'public_unlisted') }
  let!(:my_private_project) { create(:project, title: 'private mine', account: project_account, public: false, require_confidentiality: false) }
  let!(:my_public_project_business_confidential) { create(:project, title: 'private mine business confidential', account: project_account, visibility: 'public_listed', require_confidentiality: true) }
  let!(:my_archived_project) { create(:project, title: 'archived mine', account: project_account, visibility: 'archived') }

  let!(:channel) { create :channel, team: team1, project: my_public_project, name: 'channel', channel_id: 'channel' }
  let!(:other_channel) { create :channel, team: team1, project: my_private_project, name: 'other_channel', channel_id: 'other_channel' }
  let!(:confidential_channel) { create :channel, team: team1, project: my_public_project_business_confidential, name: 'confidential_channel', channel_id: 'confidential_channel' }

  let!(:other_team_member) { create(:account) }
  let!(:other_team_member_auth) { create(:authentication, account: other_team_member) }
  let!(:others_public_project) { create(:project, title: 'public someone elses', account: other_team_member, visibility: 'public_listed') }
  let!(:others_public_unlisted_project) { create(:project, title: 'public someone elses', account: other_team_member, visibility: 'public_unlisted') }
  let!(:others_private_project) { create(:project, title: 'private someone elses', account: other_team_member, public: false) }
  let!(:others_archived_project) { create(:project, title: 'archived someone elses', account: other_team_member, visibility: 'archived') }

  let!(:different_team_account) { create(:account).tap { |a| create(:authentication, account: a) } }

  before do
    team1.build_authentication_team authentication
    team1.build_authentication_team other_team_member_auth

    my_public_project.admins << project_admin
    my_public_unlisted_project.admins << project_admin
    my_private_project.admins << project_admin
    my_public_project_business_confidential.admins << project_admin
    my_archived_project.admins << project_admin
  end

  describe ProjectPolicy::Scope do
    describe '#resolve' do
      it "returns all public projects and projects that belong to the current user's team" do
        projects = ProjectPolicy::Scope.new(project_account, Project).resolve

        expect(projects.map(&:title).sort).to match_array([my_archived_project,
                                                           my_private_project,
                                                           my_public_project,
                                                           my_public_unlisted_project,
                                                           my_public_project_business_confidential,
                                                           others_public_project].map(&:title).sort)
      end

      it 'returns all public projects if account is nil' do
        projects = ProjectPolicy::Scope.new(nil, Project).resolve

        expect(projects.map(&:title).sort).to eq([my_public_project,
                                                  others_public_project,
                                                  my_public_project_business_confidential].map(&:title).sort)
      end
    end
  end

  describe '#send_award?' do
    it 'returns true if an account is the owner of a project and false otherwise' do
      not_authorized(nil, my_public_project, :send_award?)
      not_authorized(nil, my_private_project, :send_award?)

      authorized(project_account, my_public_project, :send_award?)
      authorized(project_account, my_private_project, :send_award?)

      not_authorized(other_team_member, my_public_project, :send_award?)
      not_authorized(other_team_member, my_private_project, :send_award?)

      not_authorized(different_team_account, my_public_project, :send_award?)
      not_authorized(different_team_account, my_private_project, :send_award?)
    end
  end

  describe '#show_contributions?' do
    specify do
      authorized(nil, my_public_project, :show_contributions?)
      not_authorized(nil, my_public_project_business_confidential, :show_contributions?)
      not_authorized(nil, my_private_project, :show_contributions?)
    end

    specify do
      authorized(project_account, my_public_project, :show_contributions?)
      authorized(project_account, my_public_project_business_confidential, :show_contributions?)
      authorized(project_account, my_private_project, :show_contributions?)
    end

    specify do
      authorized(other_team_member, my_public_project, :show_contributions?)
      authorized(other_team_member, my_public_project_business_confidential, :show_contributions?)
      authorized(other_team_member, my_private_project, :show_contributions?)
    end

    specify do
      authorized(different_team_account, my_public_project, :show_contributions?)
      not_authorized(different_team_account, my_public_project_business_confidential, :show_contributions?)
      not_authorized(different_team_account, my_private_project, :show_contributions?)
    end
  end

  describe '#send_community_award?' do
    it 'returns true if an account belongs to the project' do
      expect(described_class.new(nil, my_public_project).send_community_award?).to be_falsey
      expect(described_class.new(nil, my_private_project).send_community_award?).to be_falsey

      expect(described_class.new(project_account, my_public_project).send_community_award?).to be true
      expect(described_class.new(project_account, my_private_project).send_community_award?).to be true

      expect(described_class.new(other_team_member, my_public_project).send_community_award?).to be true
      expect(described_class.new(other_team_member, my_private_project).send_community_award?).to be true

      expect(described_class.new(different_team_account, my_public_project).send_community_award?).to be_falsey
      expect(described_class.new(different_team_account, my_private_project).send_community_award?).to be_falsey
    end
  end

  describe '#show? #transfers?' do
    it 'allows viewing of projects that are public_listed or owned by the current account' do
      %i[show? transfers?].each do |action|
        expect(described_class.new(nil, my_public_project).send(action)).to be true
        expect(described_class.new(nil, others_private_project).send(action)).to be_falsey
        expect(described_class.new(nil, others_archived_project).send(action)).to be_falsey

        expect(described_class.new(project_account, my_public_project).send(action)).to be true
        expect(described_class.new(project_account, my_private_project).send(action)).to be true
        expect(described_class.new(project_account, my_archived_project).send(action)).to be true
        expect(described_class.new(project_account, others_private_project).send(action)).to be false
        expect(described_class.new(project_account, others_archived_project).send(action)).to be false

        expect(described_class.new(other_team_member, others_public_project).send(action)).to be true
        expect(described_class.new(other_team_member, my_private_project).send(action)).to be true

        expect(described_class.new(different_team_account, my_public_project).send(action)).to be true
        expect(described_class.new(different_team_account, my_private_project).send(action)).to be_falsey
      end
    end
  end

  describe '#unlisted?' do
    it 'allows viewing of projects that are public_unlisted or owned by the current account' do
      expect(described_class.new(nil, my_public_unlisted_project).unlisted?).to be true
      expect(described_class.new(nil, others_private_project).unlisted?).to be_falsey
      expect(described_class.new(nil, others_archived_project).unlisted?).to be_falsey

      expect(described_class.new(project_account, my_public_unlisted_project).unlisted?).to be true
      expect(described_class.new(project_account, my_private_project).unlisted?).to be true
      expect(described_class.new(project_account, my_archived_project).unlisted?).to be true
      expect(described_class.new(project_account, others_private_project).unlisted?).to be false
      expect(described_class.new(project_account, others_archived_project).unlisted?).to be false

      expect(described_class.new(other_team_member, others_public_unlisted_project).unlisted?).to be true
      expect(described_class.new(other_team_member, my_private_project).unlisted?).to be true

      expect(described_class.new(different_team_account, my_public_unlisted_project).unlisted?).to be true
      expect(described_class.new(different_team_account, my_private_project).unlisted?).to be_falsey
    end
  end

  describe 'show_award_types?' do
    it 'allows showing award types of projects that are public or owned by the current account' do
      expect(described_class.new(nil, my_public_project).show_award_types?).to be true
      expect(described_class.new(nil, my_public_unlisted_project).show_award_types?).to be true
      expect(described_class.new(nil, others_private_project).show_award_types?).to be_falsey
      expect(described_class.new(nil, others_archived_project).show_award_types?).to be_falsey

      expect(described_class.new(project_account, my_public_project).show_award_types?).to be true
      expect(described_class.new(project_account, my_public_unlisted_project).show_award_types?).to be true
      expect(described_class.new(project_account, my_private_project).show_award_types?).to be true
      expect(described_class.new(project_account, my_archived_project).show_award_types?).to be true
      expect(described_class.new(project_account, others_private_project).show_award_types?).to be false
      expect(described_class.new(project_account, others_archived_project).show_award_types?).to be false

      expect(described_class.new(other_team_member, others_public_project).show_award_types?).to be true
      expect(described_class.new(other_team_member, my_private_project).show_award_types?).to be true

      expect(described_class.new(different_team_account, my_public_project).show_award_types?).to be true
      expect(described_class.new(different_team_account, my_public_unlisted_project).show_award_types?).to be true
      expect(described_class.new(different_team_account, my_private_project).show_award_types?).to be_falsey
    end
  end

  describe 'edit? update? send_award? admins? add_admin? remove_admin? create_transfer?' do
    it 'only allows managing projects that are owned or administrated by the current account' do
      %i[edit? update? send_award? admins? add_admin? remove_admin? create_transfer?].each do |action|
        expect(described_class.new(nil, my_public_project).send(action)).to be_falsey
        expect(described_class.new(nil, others_private_project).send(action)).to be_falsey
        expect(described_class.new(nil, my_archived_project).send(action)).to be_falsey

        expect(described_class.new(project_account, my_public_project).send(action)).to be true
        expect(described_class.new(project_account, my_private_project).send(action)).to be true
        expect(described_class.new(project_account, my_archived_project).send(action)).to be true

        expect(described_class.new(project_admin, my_public_project).send(action)).to be true
        expect(described_class.new(project_admin, my_private_project).send(action)).to be true
        expect(described_class.new(project_admin, my_archived_project).send(action)).to be true

        expect(described_class.new(project_account, others_public_project).send(action)).to be_falsey
        expect(described_class.new(project_account, others_private_project).send(action)).to be_falsey
        expect(described_class.new(project_account, others_archived_project).send(action)).to be_falsey

        expect(described_class.new(other_team_member, my_public_project).send(action)).to be_falsey
        expect(described_class.new(other_team_member, my_private_project).send(action)).to be_falsey
        expect(described_class.new(other_team_member, my_archived_project).send(action)).to be_falsey

        expect(described_class.new(different_team_account, my_public_project).send(action)).to be_falsey
        expect(described_class.new(different_team_account, my_private_project).send(action)).to be_falsey
        expect(described_class.new(different_team_account, my_archived_project).send(action)).to be_falsey
      end
    end
  end

  permissions :team_member?, :send_community_award? do
    specify { expect(described_class).to permit(project_account, my_public_project) }
    specify { expect(described_class).to permit(other_team_member, my_public_project) }

    specify { expect(described_class).not_to permit(different_team_account, my_public_project) }
    specify { expect(described_class).not_to permit(nil, my_public_project) }
  end

  describe 'project_admin?' do
    specify { expect(described_class.new(project_admin, my_public_project).project_admin?).to be_truthy }
    specify { expect(described_class.new(different_team_account, my_public_project).project_admin?).to be_falsey }
    specify { expect(described_class.new(nil, my_public_project).project_admin?).to be_falsey }
  end

  def authorized(*args, method)
    expect(ProjectPolicy.new(*args).send(method)).to eq(true)
  end

  def not_authorized(*args, method)
    expect(ProjectPolicy.new(*args).send(method)).to be_falsey
  end
end
