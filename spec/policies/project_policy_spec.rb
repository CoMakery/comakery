require 'rails_helper'

describe ProjectPolicy do
  let!(:team1) { create :team }
  let!(:team2) { create :team }
  let!(:project_account) { create :account }
  let!(:project_admin) { create :account }
  let!(:project_contributor) { create :account }
  let!(:project_interested) { create :account }
  let!(:project_observer) { create :account }
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

  let(:projects) do
    [
      my_public_project, my_public_unlisted_project, my_private_project, my_archived_project,
      others_private_project, others_archived_project, others_public_project
    ]
  end

  before do
    team1.build_authentication_team authentication
    team1.build_authentication_team other_team_member_auth

    [my_public_project, my_public_unlisted_project, my_public_project_business_confidential, my_private_project, my_archived_project].each do |pr|
      create(:award, award_type: create(:award_type, project: pr), account: project_contributor)
      create(:project_role, project: pr, account: project_interested)
      create(:project_role, project: pr, account: project_observer, role: :observer)
      create(:project_role, project: pr, account: project_admin, role: :admin)
    end
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
                                                  my_public_project_business_confidential,
                                                  others_public_project].map(&:title).sort)
      end

      context 'for whitelabels' do
        let!(:my_whitelabel_non_confidential_project) { create(:project, title: 'whitelabel non-confidential', account: project_account, visibility: 'public_listed', require_confidentiality: false, mission: create(:mission, whitelabel: true)) }
        let!(:my_whitelabel_confidential_project) { create(:project, title: 'whitelabel confidential', account: project_account, visibility: 'public_listed', require_confidentiality: true, mission: create(:mission, whitelabel: true)) }

        it 'returns all public non-confidential projects for whitelabels if account is nil' do
          whitelabel_projects = Project.where(whitelabel: true)
          projects = ProjectPolicy::Scope.new(nil, whitelabel_projects).resolve

          expect(projects.map(&:title).sort).to eq([my_whitelabel_non_confidential_project].map(&:title).sort)
        end

        it 'returns all public confidential and non-confidential projects for whitelabels if account has access' do
          whitelabel_projects = Project.where(whitelabel: true)
          projects = ProjectPolicy::Scope.new(project_account, whitelabel_projects).resolve

          expect(projects.map(&:title).sort).to eq([my_whitelabel_confidential_project,
                                                    my_whitelabel_non_confidential_project].map(&:title).sort)
        end
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
      not_authorized(other_team_member, my_public_project_business_confidential, :show_contributions?)
      authorized(other_team_member, my_private_project, :show_contributions?)
    end

    specify do
      authorized(different_team_account, my_public_project, :show_contributions?)
      not_authorized(different_team_account, my_public_project_business_confidential, :show_contributions?)
      not_authorized(different_team_account, my_private_project, :show_contributions?)
    end
  end

  describe '#accounts?' do
    context 'without user' do
      it { expect(described_class.new(nil, my_public_project).accounts?).to be(true) }

      it { expect(described_class.new(nil, my_private_project).accounts?).to be(false) }

      it { expect(described_class.new(nil, my_public_project_business_confidential).accounts?).to be(false) }
    end

    context 'when user is observer' do
      it { expect(described_class.new(project_observer, my_public_project).accounts?).to be(true) }

      it { expect(described_class.new(project_observer, my_private_project).accounts?).to be(true) }

      it { expect(described_class.new(project_observer, my_public_project_business_confidential).accounts?).to be(true) }
    end

    context 'when user is interested' do
      it { expect(described_class.new(project_interested, my_public_project).accounts?).to be(true) }

      it { expect(described_class.new(project_interested, my_private_project).accounts?).to be(false) }

      it { expect(described_class.new(project_interested, my_public_project_business_confidential).accounts?).to be(false) }
    end
  end

  describe '#transfers?' do
    context 'without user' do
      it { expect(described_class.new(nil, my_public_project).transfers?).to be(true) }

      it { expect(described_class.new(nil, my_private_project).transfers?).to be(false) }

      it { expect(described_class.new(nil, my_public_project_business_confidential).transfers?).to be(false) }
    end

    context 'when user is observer' do
      it { expect(described_class.new(project_observer, my_public_project).transfers?).to be(true) }

      it { expect(described_class.new(project_observer, my_private_project).transfers?).to be(true) }

      it { expect(described_class.new(project_observer, my_public_project_business_confidential).transfers?).to be(true) }
    end

    context 'without user is interested' do
      it { expect(described_class.new(project_interested, my_public_project).transfers?).to be(true) }

      it { expect(described_class.new(project_interested, my_private_project).transfers?).to be(false) }

      it { expect(described_class.new(project_interested, my_public_project_business_confidential).transfers?).to be(false) }
    end
  end

  permissions :export_transfers? do
    subject { described_class }

    it { is_expected.to permit(project_account, my_public_project) }
    it { is_expected.to permit(project_admin, my_public_project) }
    it { is_expected.to permit(project_observer, my_public_project) }

    it { is_expected.not_to permit(nil, my_public_project) }
    it { is_expected.not_to permit(project_interested, my_public_project) }
    it { is_expected.not_to permit(other_team_member, my_public_project) }
    it { is_expected.not_to permit(project_contributor, my_public_project) }
  end

  describe 'show_transfer_rules?' do
    let!(:my_public_project_w_comakery_token) { create(:project, title: 'public mine', account: project_account, visibility: 'public_listed', token: create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten)) }

    it 'returns true for projects with truthy show_contributions supporting transfer rules' do
      authorized(nil, my_public_project_w_comakery_token, :show_transfer_rules?)
      not_authorized(nil, my_public_project, :show_transfer_rules?)
    end
  end

  describe '#show?' do
    it 'allows viewing of projects that are public_listed or owned by the current account' do
      %i[show?].each do |action|
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
    context 'when project with non-whitelabel or without mission' do
      it 'allows show award types of projects that are public or owned by the current account' do
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
  end

  describe 'show_whitelabel_award_types?' do
    let(:whitelabel_mission) { create :whitelabel_mission }

    before { projects.each { |project| project.update(mission: whitelabel_mission) } }

    context 'when project awards is visible' do
      before { projects.each { |project| project.mission.update(project_awards_visible: true) } }

      it 'shows award types' do
        expect(described_class.new(nil, my_public_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(nil, my_public_unlisted_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(nil, others_private_project).show_whitelabel_award_types?).to be_falsey
        expect(described_class.new(nil, others_archived_project).show_whitelabel_award_types?).to be_falsey

        expect(described_class.new(project_account, my_public_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(project_account, my_public_unlisted_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(project_account, my_private_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(project_account, my_archived_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(project_account, others_private_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, others_archived_project).show_whitelabel_award_types?).to be false

        expect(described_class.new(other_team_member, others_public_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(other_team_member, my_private_project).show_whitelabel_award_types?).to be true

        expect(described_class.new(different_team_account, my_public_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(different_team_account, my_public_unlisted_project).show_whitelabel_award_types?).to be true
        expect(described_class.new(different_team_account, my_private_project).show_whitelabel_award_types?).to be_falsey
      end
    end

    context 'when project awards visibility is hidden' do
      before { projects.each { |project| project.mission.update(project_awards_visible: false) } }

      it 'prohibits show project award types' do
        expect(described_class.new(nil, my_public_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(nil, my_public_unlisted_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(nil, others_private_project).show_whitelabel_award_types?).to be_falsey
        expect(described_class.new(nil, others_archived_project).show_whitelabel_award_types?).to be_falsey

        expect(described_class.new(project_account, my_public_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, my_public_unlisted_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, my_private_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, my_archived_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, others_private_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(project_account, others_archived_project).show_whitelabel_award_types?).to be false

        expect(described_class.new(other_team_member, others_public_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(other_team_member, my_private_project).show_whitelabel_award_types?).to be false

        expect(described_class.new(different_team_account, my_public_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(different_team_account, my_public_unlisted_project).show_whitelabel_award_types?).to be false
        expect(described_class.new(different_team_account, my_private_project).show_whitelabel_award_types?).to be_falsey
      end
    end
  end

  describe 'edit? update? send_award? accesses? regenerate_api_key? add_admin? remove_admin? create_transfer? edit_reg_groups? edit_transfer_rules? freeze_token? transfer_types? export_transfers?' do
    it 'only allows managing projects that are owned or administrated by the current account' do
      %i[edit? update? send_award? accesses? regenerate_api_key? add_admin? remove_admin? create_transfer? edit_reg_groups? edit_transfer_rules? freeze_token? transfer_types? export_transfers?].each do |action|
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

  permissions :team_member? do
    specify { expect(described_class).to permit(project_account, my_public_project) }
    specify { expect(described_class).to permit(project_admin, my_public_project) }
    specify { expect(described_class).to permit(project_contributor, my_public_project) }
    specify { expect(described_class).to permit(other_team_member, my_public_project) }

    specify { expect(described_class).not_to permit(different_team_account, my_public_project) }
    specify { expect(described_class).not_to permit(project_interested, my_public_project) }
    specify { expect(described_class).not_to permit(nil, my_public_project) }
  end

  describe 'project_admin?' do
    specify { expect(described_class.new(project_admin, my_public_project).project_admin?).to be_truthy }
    specify { expect(described_class.new(different_team_account, my_public_project).project_admin?).to be_falsey }
    specify { expect(described_class.new(nil, my_public_project).project_admin?).to be_falsey }
  end

  describe '#refresh_transfer_rules?' do
    specify 'project admin' do
      expect(described_class.new(project_admin, my_public_project).refresh_transfer_rules?).to be true
    end

    specify 'project owner' do
      expect(described_class.new(project_account, my_public_project).refresh_transfer_rules?).to be true
    end

    specify 'other team member' do
      expect(described_class.new(other_team_member, my_public_project).refresh_transfer_rules?).to be false
    end
  end

  def authorized(*args, method)
    expect(ProjectPolicy.new(*args).send(method)).to eq(true)
  end

  def not_authorized(*args, method)
    expect(ProjectPolicy.new(*args).send(method)).to be_falsey
  end
end
