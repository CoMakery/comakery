require 'rails_helper'
require 'models/concerns/has_one_attached_and_prepare_image_spec'

describe Account do
  it_behaves_like 'has_one_attached_and_prepare_image', 'image', resize: '190x190!'

  it { is_expected.to have_many(:wallets).dependent(:destroy) }
  it { is_expected.to have_many(:balances).through(:wallets) }
  it { is_expected.to have_one(:ore_id_account).dependent(:destroy) }
  it { is_expected.to have_many(:invites).dependent(:destroy) }

  subject(:account) { create :account, password: '12345678' }

  before do
    stub_discord_channels
  end

  specify { expect(subject.name).to eq("#{subject.first_name} #{subject.last_name}") }

  context 'when created from an invite' do
    let(:invite) { FactoryBot.build(:invite) }

    context 'and email matches invite email' do
      subject { FactoryBot.build(:account, :unconfirmed, email: invite.email, invite: invite) }

      before do
        subject.valid?
      end

      it { is_expected.to be_confirmed }
      it { is_expected.to be_valid }
    end

    context 'and email matches invite email in a different case' do
      subject { FactoryBot.build(:account, :unconfirmed, email: invite.email.upcase, invite: invite) }

      before do
        subject.valid?
      end

      it { is_expected.to be_confirmed }
      it { is_expected.to be_valid }
    end

    context 'and email doesnt match invite email' do
      subject { FactoryBot.build(:account, :unconfirmed, invite: invite) }

      before do
        subject.valid?
      end

      it { is_expected.not_to be_confirmed }
      it { is_expected.to be_valid }

      context 'and invite forces the email to match' do
        let(:invite) { FactoryBot.build(:invite, force_email: true) }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe 'validations' do
    describe 'urls' do
      let!(:account) do
        create :account,
               linkedin_url: 'https://www.linkedin.com/',
               github_url: 'https://github.com/',
               dribble_url: 'https://dribbble.com/',
               behance_url: 'https://www.behance.net/'
      end

      it 'validates urls' do
        expect(account).to be_valid
      end

      it 'validates linkedin_url' do
        account.linkedin_url = 'http://google.com'
        expect(account).not_to be_valid
      end

      it 'validates github_url' do
        account.github_url = 'http://google.com'
        expect(account).not_to be_valid
      end

      it 'validates dribble_url' do
        account.dribble_url = 'http://google.com'
        expect(account).not_to be_valid
      end

      it 'validates behance_url' do
        account.behance_url = 'http://google.com'
        expect(account).not_to be_valid
      end

      it 'validates sanity of linkedin_url' do
        account.linkedin_url = 'https://www.linkedin.com/<script>alert(1)</script>'
        expect(account).not_to be_valid
      end

      it 'validates sanity of github_url' do
        account.github_url = 'https://github.com/<script>alert(1)</script>'
        expect(account).not_to be_valid
      end

      it 'validates sanity of dribble_url' do
        account.dribble_url = 'https://dribbble.com/<script>alert(1)</script>'
        expect(account).not_to be_valid
      end

      it 'validates sanity of behance_url' do
        account.behance_url = 'https://www.behance.net/<script>alert(1)</script>'
        expect(account).not_to be_valid
      end

      it 'doesnt allow non-unique emails on Comakery' do
        account2 = build(:account, email: account.email)

        expect(account2).not_to be_valid
      end

      it 'doesnt allow non-unique emails on a whitelabel' do
        managed_account = create(:account, managed_mission: create(:mission))
        managed_account2 = build(:account, managed_mission: managed_account.managed_mission, email: managed_account.email)

        expect(managed_account2).not_to be_valid
      end

      it 'allows non-unique emails between whitelabels and Comakery' do
        managed_account = create(:account, managed_mission: create(:mission), email: account.email)
        managed_account2 = create(:account, managed_mission: create(:mission), email: account.email)

        expect(managed_account).to be_valid
        expect(managed_account2).to be_valid
      end

      it 'doesnt allow non-unique managed_account_id on a whitelabel' do
        managed_account = create(:account, managed_mission: create(:mission))
        managed_account2 = build(:account, managed_mission: managed_account.managed_mission, managed_account_id: managed_account.managed_account_id)

        expect(managed_account2).not_to be_valid
      end

      it 'allows non-unique managed_account_id between whitelabels' do
        managed_account = create(:account, managed_mission: create(:mission))
        managed_account2 = create(:account, managed_mission: create(:mission), managed_account_id: managed_account.managed_account_id)

        expect(managed_account).to be_valid
        expect(managed_account2).to be_valid
      end
    end

    it 'requires many attributes' do
      expect(described_class.new.tap(&:valid?).errors.full_messages.sort).to eq(["Email can't be blank"])
    end
  end

  describe 'callbacks' do
    describe 'populate_awards' do
      context 'on account creation' do
        let!(:email) { 'test_populate_awards@comakery.com' }
        let!(:award) { create(:award, status: :accepted, email: email) }
        let!(:account) { create(:account, email: email) }

        it 'associates awards issued to account email address' do
          expect(account.reload.awards).to include(award)
          expect(award.reload.account).to eq(account)
        end
      end
    end

    describe 'normalize_ethereum_auth_address' do
      context 'with valid address' do
        let!(:account) { create(:account, ethereum_auth_address: '0xf4258b3415cab41fc9ce5f9b159ab21ede0501b1') }

        it 'applies checksum to address' do
          expect(account.ethereum_auth_address).to eq('0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1')
        end
      end
    end

    describe 'broadcast_destroy' do
      context 'on account destroy' do
        let(:mission) { create(:mission) }
        let(:account) { create(:account, managed_mission: mission) }
        let!(:wallet1) { create(:wallet, account: account, address: build(:bitcoin_address_1)) }
        let!(:wallet2) { create(:eth_wallet, account: account) }
        let!(:wallet3) { create(:wallet, address: build(:bitcoin_address_2)) }

        before { allow(Turbo::StreamsChannel).to receive(:broadcast_remove_to) }

        it 'should broadcast related wallets removal' do
          account.destroy!

          expect(Turbo::StreamsChannel)
            .to have_received(:broadcast_remove_to)
            .with "mission_#{mission.id}_account_wallets",
                  target: "account_#{account.id}_wallet_#{wallet1.id}"
          expect(Turbo::StreamsChannel)
            .to have_received(:broadcast_remove_to)
            .with "mission_#{mission.id}_account_wallets",
                  target: "account_#{account.id}_wallet_#{wallet2.id}"

          expect(Turbo::StreamsChannel)
            .not_to have_received(:broadcast_remove_to)
            .with "mission_#{mission.id}_account_wallets",
                  target: "account_#{account.id}_wallet_#{wallet3.id}"

          expect(Turbo::StreamsChannel).to have_received(:broadcast_remove_to).twice
        end
      end
    end
  end

  it 'enforces unique emails, case-insensitively' do
    create :account, email: 'alice@example.com'
    expect { create :account, email: 'Alice@example.com' }.to raise_error(ActiveRecord::RecordInvalid)
  end

  # this is kind of unfortunate --
  # would be better with a "email-as-entered" field and
  # a separate lowercase "email-as-authenticated-username" field
  it 'makes emails all lowercase' do
    alice = create :account, email: 'ALICE@example.com'
    expect(alice.email).to eq('alice@example.com')
  end

  describe '#slack' do
    context 'creates a new Slack instance if none exists' do
      before do
        create :authentication, provider: 'slack', account: subject
        subject.instance_variable_set(:@slack, nil)
      end
      specify do
        expect(subject.slack).to be_instance_of Comakery::Slack
      end
    end

    context 'returns Slack instance if exists' do
      let!(:slack) { build :slack }

      before { subject.instance_variable_set(:@slack, slack) }
      specify do
        expect(subject.slack).to eq slack
      end
    end
  end

  describe '#slack_auth' do
    let!(:slack_authentication) { create(:authentication, provider: 'slack', account: subject) }
    let!(:other_authentication) { create(:authentication, provider: 'other', account: subject) }

    it "returns the authentication associated with this account that is from the 'slack' provider" do
      expect(subject.slack_auth).to eq(slack_authentication)
    end
  end

  describe 'authorize using password' do
    it 'does not accept invalid password' do
      expect(subject.authenticate('notright')).to be false
    end
    it 'returns account for valid password' do
      expect(subject.authenticate('12345678')).to eq subject
    end
  end

  describe 'associations' do
    let!(:account) { create(:account, unverified: true) }
    let!(:project) { create(:project, account: account) }
    let!(:admin_project) { create(:project) }
    let!(:admin_award_type) { create(:award_type, project: admin_project) }
    let!(:admin_award) { create(:award, award_type: admin_award_type) }
    let!(:award_type) { create(:award_type, project: project) }
    let!(:award) { create(:award, award_type: award_type, issuer: account) }
    let!(:team) { create :team }
    let!(:teammate) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:authentication_teammate) { create :authentication, account: teammate }
    let!(:teammate_project) { create(:project, account: teammate) }
    let!(:teammate_award_type) { create(:award_type, project: teammate_project) }
    let!(:teammate_award) { create(:award, award_type: teammate_award_type, issuer: teammate) }
    let!(:verification) { create(:verification, account: account) }
    let!(:verification2) { create(:verification, account: account) }
    let!(:provided_verification) { create(:verification, provider: account) }
    let!(:account_token_record) { create(:account_token_record, account: account) }
    let!(:managed_account) { create(:account, managed_mission: create(:mission)) }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication_teammate
      create(:channel, team: team, project: teammate_project, channel_id: 'general')
      admin_project.project_admins << account
    end

    it 'has many projects' do
      expect(account.projects).to match_array([project])
    end

    it 'has many team projects' do
      expect(account.team_projects).to match_array([teammate_project])
    end

    it 'has many team awards' do
      expect(account.team_awards).to match_array([teammate_award])
    end

    it 'has many issued awards' do
      expect(account.issued_awards).to match_array([award])
    end

    it 'has many award types' do
      expect(account.award_types).to match_array([award_type])
    end

    it 'has many team award types' do
      expect(account.team_award_types).to match_array([teammate_award_type])
    end

    it 'has many admin_projects' do
      expect(account.admin_projects).to match_array([admin_project, project]) # owner as admin
    end

    it 'has many admin award_types' do
      expect(account.admin_award_types).to match_array([admin_award_type, award_type]) # same for owner
    end

    it 'has many admin awards' do
      expect(account.admin_awards).to match_array([admin_award, award]) # same for owner
    end

    it 'has many verifications' do
      expect(account.verifications).to match_array([verification, verification2])
    end

    it 'belongs to latest verification' do
      expect(account.latest_verification).to eq(verification2)
    end

    it 'has many provided verifications' do
      expect(account.provided_verifications).to match_array([provided_verification])
    end

    it 'has many account_token_records' do
      expect(account.account_token_records).to match_array([account_token_record])
    end

    it 'belongs to managed_mission' do
      expect(managed_account.managed_mission).not_to be_nil
    end
  end

  describe '.accessable_award_types' do
    let!(:account) { create(:account) }
    let!(:project) { create(:project, account: account) }
    let!(:admin_project) { create(:project) }
    let!(:admin_award_type) { create(:award_type, project: admin_project) }
    let!(:admin_award) { create(:award, award_type: admin_award_type) }
    let!(:award_type) { create(:award_type, project: project) }
    let!(:team) { create :team }
    let!(:teammate) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:authentication_teammate) { create :authentication, account: teammate }
    let!(:teammate_project) { create(:project, account: teammate) }
    let!(:teammate_award_type) { create(:award_type, project: teammate_project) }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication_teammate
      create(:channel, team: team, project: teammate_project, channel_id: 'general')
      admin_project.project_admins << account
    end

    it 'returns own award types' do
      expect(account.accessable_award_types).to include(award_type)
    end

    it 'returns team award types' do
      expect(account.accessable_award_types).to include(teammate_award_type)
    end

    it 'returns admin award types' do
      expect(account.accessable_award_types).to include(admin_award_type)
    end

    it 'returns award types from accessable projects' do
      accessable_project = create(:project, visibility: 'public_listed')
      accessable_award_type = create(:award_type, project: accessable_project)

      expect(account.accessable_award_types).to include(accessable_award_type)
    end
  end

  describe '.accessable_awards' do
    let!(:account) { create(:account) }
    let!(:project) { create(:project, account: account) }
    let!(:admin_project) { create(:project) }
    let!(:admin_award_type) { create(:award_type, project: admin_project) }
    let!(:admin_award) { create(:award, award_type: admin_award_type) }
    let!(:award_type) { create(:award_type, project: project) }
    let!(:award) { create(:award, award_type: award_type, issuer: account) }
    let!(:started_award) { create(:award, status: :started, account: account) }
    let!(:received_award) { create(:award, award_type: award_type, account: account) }
    let!(:team) { create :team }
    let!(:teammate) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:authentication_teammate) { create :authentication, account: teammate }
    let!(:teammate_project) { create(:project, account: teammate) }
    let!(:teammate_award_type) { create(:award_type, project: teammate_project) }
    let!(:teammate_award) { create(:award, award_type: teammate_award_type, issuer: teammate) }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication_teammate
      create(:channel, team: team, project: teammate_project, channel_id: 'general')

      Award::EXPERIENCE_LEVELS['Demonstrated Skills'].times do
        create(:award, account: account, specialty: account.specialty)
      end

      admin_project.project_admins << account
    end

    it 'returns started awards' do
      expect(account.accessable_awards).to include(started_award)
    end

    it 'returns received awards' do
      expect(account.accessable_awards).to include(received_award)
    end

    it 'returns issued awards' do
      expect(account.accessable_awards).to include(award)
    end

    it 'returns team issued awards' do
      expect(account.accessable_awards).to include(teammate_award)
    end

    it 'returns admin awards' do
      expect(account.accessable_awards).to include(admin_award)
    end

    it 'returns awards from accessable award types with ready state and matching experience' do
      accessable_project = create(:project, visibility: 'public_listed')
      accessable_award_type = create(:award_type, project: accessable_project)
      award_w_matching_experience = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Demonstrated Skills'])
      award_w_not_matching_experience = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Established Contributor'])
      award_in_ready_state = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type)
      award_in_non_ready_state = create(:award, specialty: account.specialty, award_type: accessable_award_type)

      expect(account.accessable_awards).to include(award_in_ready_state)
      expect(account.accessable_awards).not_to include(award_in_non_ready_state)
      expect(account.accessable_awards).to include(award_w_matching_experience)
      expect(account.accessable_awards).not_to include(award_w_not_matching_experience)
    end

    it 'rejects ready awards reached_maximum_assignments_for self' do
      account = create(:account)
      award_account_cloned_max = create(:award_ready, number_of_assignments: 10, number_of_assignments_per_user: 1)
      award_account_cloned_max.project.update(visibility: :public_listed)
      award_account_cloned_max.clone_on_assignment.update!(account: account)

      expect(account.accessable_awards).not_to include(award_account_cloned_max)
    end
  end

  describe '.awards_matching_experience' do
    let!(:account) { create(:account) }
    let!(:project) { create(:project, account: account) }
    let!(:award_type) { create(:award_type, project: project) }
    let!(:award) { create(:award, award_type: award_type, issuer: account) }
    let!(:received_award) { create(:award, award_type: award_type, account: account) }
    let!(:team) { create :team }
    let!(:teammate) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:authentication_teammate) { create :authentication, account: teammate }
    let!(:teammate_project) { create(:project, account: teammate) }
    let!(:teammate_award_type) { create(:award_type, project: teammate_project) }
    let!(:teammate_award) { create(:award, award_type: teammate_award_type, issuer: teammate) }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication_teammate
      create(:channel, team: team, project: teammate_project, channel_id: 'general')

      Award::EXPERIENCE_LEVELS['Demonstrated Skills'].times do
        create(:award, account: account, specialty: account.specialty)
      end
    end

    it 'returns awards from accessable award types with ready state and matching experience' do
      accessable_project = create(:project, visibility: 'public_listed')
      accessable_award_type = create(:award_type, project: accessable_project)
      award_w_matching_experience = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Demonstrated Skills'])
      award_w_zero_experience = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type)
      award_w_not_matching_experience = create(:award_ready, specialty: account.specialty, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Established Contributor'])
      award_w_matching_generic_experience = create(:award_ready, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Demonstrated Skills'])
      award_w_not_matching_generic_experience = create(:award_ready, award_type: accessable_award_type, experience_level: Award::EXPERIENCE_LEVELS['Established Contributor'])
      award_w_zero_generic_experience = create(:award_ready, award_type: accessable_award_type)
      award_in_non_ready_state = create(:award, specialty: account.specialty, award_type: accessable_award_type)

      expect(account.awards_matching_experience).to include(award_w_matching_experience)
      expect(account.awards_matching_experience).to include(award_w_zero_experience)
      expect(account.awards_matching_experience).to include(award_w_matching_generic_experience)
      expect(account.awards_matching_experience).to include(award_w_zero_generic_experience)
      expect(account.awards_matching_experience).not_to include(award_in_non_ready_state)
      expect(account.awards_matching_experience).not_to include(award_w_not_matching_generic_experience)
      expect(account.awards_matching_experience).not_to include(award_w_not_matching_experience)
    end
  end

  describe '.related_awards' do
    let!(:account) { create(:account) }
    let!(:project) { create(:project, account: account) }
    let!(:admin_project) { create(:project) }
    let!(:admin_award_type) { create(:award_type, project: admin_project) }
    let!(:admin_award) { create(:award, award_type: admin_award_type) }
    let!(:award_type) { create(:award_type, project: project) }
    let!(:award) { create(:award, award_type: award_type, issuer: account) }
    let!(:received_award) { create(:award, award_type: award_type, account: account) }
    let!(:team) { create :team }
    let!(:teammate) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:authentication_teammate) { create :authentication, account: teammate }
    let!(:teammate_project) { create(:project, account: teammate) }
    let!(:teammate_award_type) { create(:award_type, project: teammate_project) }
    let!(:teammate_award) { create(:award, award_type: teammate_award_type, issuer: teammate) }
    let!(:awarded_project) { create(:award, account: account).project }
    let!(:award_from_awarded_project) { create(:award, status: :ready, award_type: create(:award_type, project: awarded_project)) }
    let!(:award_w_not_matching_exp_from_awarded_project) { create(:award, status: :ready, experience_level: 10, award_type: create(:award_type, project: awarded_project)) }
    let!(:archived_awarded_project) do
      pr = create(:award, account: account).project
      pr.archived!
      pr
    end
    let!(:award_from_archived_awarded_project) { create(:award, status: :ready, award_type: create(:award_type, project: archived_awarded_project)) }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication_teammate
      create(:channel, team: team, project: teammate_project, channel_id: 'general')
      admin_project.project_admins << account
    end

    it 'returns received awards' do
      expect(account.related_awards).to include(received_award)
    end

    it 'returns issued awards' do
      expect(account.related_awards).to include(award)
    end

    it 'returns team issued awards' do
      expect(account.related_awards).to include(teammate_award)
    end

    it 'returns admin awards' do
      expect(account.accessable_awards).to include(admin_award)
    end

    it 'returns awards from awarded projects' do
      expect(account.accessable_awards).to include(award_from_awarded_project)
    end

    it 'doesnt return awards with not matching exp from awarded projects' do
      expect(account.accessable_awards).not_to include(award_w_not_matching_exp_from_awarded_project)
    end

    it 'doesnt return awards from archived awarded projects' do
      expect(account.accessable_awards).not_to include(award_from_archived_awarded_project)
    end
  end

  describe '.experience_for(specialty)' do
    let(:account) { create(:account, specialty: create(:specialty)) }

    before do
      3.times { create(:award, specialty: account.specialty, account: account) }
      1.times { create(:award, account: account) }
    end

    it 'returns number of completed awards for given specialty' do
      expect(account.experience_for(account.specialty)).to eq(3)
    end
  end

  describe '.tasks_to_unlock(award)' do
    let(:account) { create(:account) }
    let(:award_with_higher_exp_level) { create(:award, experience_level: Award::EXPERIENCE_LEVELS['Demonstrated Skills']) }

    before do
      create(:award, award_type: award_with_higher_exp_level.award_type, account: account)
    end

    it 'returns number of tasks to be completed to achieve exp level suitable for a given award' do
      expect(account.tasks_to_unlock(award_with_higher_exp_level)).to eq(award_with_higher_exp_level.experience_level - account.experience_for(award_with_higher_exp_level.specialty))
    end
  end

  describe 'my projects' do
    let!(:team) { create :team }
    let!(:authentication) { create :authentication, account: account }
    let!(:account1) { create :account }
    let!(:authentication1) { create :authentication, account: account1 }
    let!(:project1) { create :project, account: account, visibility: 'member', title: 'my private project' }
    let!(:project2) { create :project, account: account, visibility: 'public_listed', title: 'my public project' }
    let!(:project3) { create :project, account: account, visibility: 'archived', title: 'archived project' }
    let!(:project4) { create :project, account: account, visibility: 'public_unlisted', title: 'unlisted project' }
    let!(:project5) { create :project, account: account1, visibility: 'member', title: 'member project' }
    let!(:project6) { create :project, visibility: 'member', title: 'other team project' }
    let!(:project7) { create :project, visibility: 'member', title: 'award project' }
    let!(:admin_project) { create(:project, title: 'admin project') }
    let!(:award_type) { create :award_type, project: project7 }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team authentication1
      admin_project.project_admins << account
    end

    it 'applies scope' do
      scope = Project.where.not(title: project2.title).where.not(title: project6.title)

      expect(account.accessable_projects(scope)).not_to include(project2)
      expect(account.my_projects(scope)).not_to include(project2)
      expect(account.other_member_projects(scope)).not_to include(project6)
    end

    it 'accessable prọjects include my own project' do
      expect(account.accessable_projects.map(&:title)).to match_array ['admin project', 'my private project', 'my public project', 'archived project', 'unlisted project']
    end

    it 'accessable prọjects include admin project' do
      expect(account.accessable_projects).to include(admin_project)
    end

    it 'accessable prọjects include other public project' do
      project6.public_listed!
      expect(account.accessable_projects.map(&:title)).to match_array ['admin project', 'my private project', 'my public project', 'archived project', 'unlisted project', 'other team project']
    end

    it 'accessable prọjects include team member project' do
      project5.channels.create(team: team, channel_id: 'general')
      expect(account.accessable_projects.map(&:title)).to match_array ['admin project', 'my private project', 'my public project', 'archived project', 'unlisted project', 'member project']
    end

    it '#other_member_projects' do
      project5.channels.create(team: team, channel_id: 'general')
      expect(account.other_member_projects.map(&:title)).to match_array ['member project']
    end

    it '#other_member_projects including award projects' do
      create :award, award_type: award_type, account: account
      expect(account.other_member_projects.map(&:title)).to match_array ['award project']
    end
  end

  it 'confirm email' do
    account = create :account, email_confirm_token: '12345'
    expect(account.confirmed?).to be_falsey
    account.confirm!
    expect(account.reload.confirmed?).to be_truthy
  end

  it 'return array of award by project' do
    account = create :account
    project = create :project
    award_type = create :award_type, project: project, name: 'type 1'
    award_type1 = create :award_type, project: project, name: 'type 2'
    create :award, award_type: award_type, amount: 10, account: account
    create :award, award_type: award_type1, amount: 20, account: account
    expect(account.award_by_project(project)).to eq [{ name: 'type 2', total: 20 }, { name: 'type 1', total: 10 }]
  end
  describe 'team projects' do
    let!(:team) { create :team }
    let!(:account) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:team_account) { create :account }
    let!(:team_authentication) { create :authentication, account: team_account }
    let!(:project) { create :project, account: account }
    let!(:team_project) { create :project, account: team_account }

    before do
      team.build_authentication_team authentication
      team.build_authentication_team team_authentication
      create :channel, team: team, project: team_project, channel_id: 'general'
    end

    it 'return projects of same team members' do
      expect(account.other_member_projects.map(&:id)).to eq [team_project.id]
    end

    it 'check if a project in same team' do
      other_project = create :project
      expect(account.same_team_project?(project)).to be_falsey
      expect(account.same_team_project?(other_project)).to be_falsey
      expect(account.same_team_project?(team_project)).to be_truthy
    end
    it 'check if a project in same team or self owned' do
      other_project = create :project
      awarded_project = create(:award, account: account).project

      expect(account.same_team_or_owned_project?(project)).to be_truthy
      expect(account.same_team_or_owned_project?(other_project)).to be_falsey
      expect(account.same_team_or_owned_project?(team_project)).to be_truthy
      expect(account.same_team_or_owned_project?(awarded_project)).to be_truthy
    end
  end

  it 'send send_reset_password_request' do
    account.send_reset_password_request(nil)
    expect(account.reset_password_token).not_to be_nil
  end

  it 'set account to unconfirm it update email' do
    account.email = 'new@test.st'
    account.save
    expect(account.reload.confirmed?).to be_falsey
  end

  it '#downcase_email' do
    account.email = 'NEW@TEST.st'
    account.save
    expect(account.reload.email).to eq 'new@test.st'
  end

  it 'awards_csv' do
    award = create(:award, account: account)
    award = award.decorate
    expect(CSV.parse(account.awards_csv, col_sep: "\t", encoding: 'utf-16le')).to eq([["\uFEFFProject", 'Award Type', 'Total Amount', 'Issuer', 'Date'], ['Uber for Cats', 'Contribution', '50.00000000', award.issuer_display_name, award.created_at.strftime('%b %d, %Y')]].map { |row| row.map { |cell| cell.encode 'utf-16le' } })
  end

  describe 'whitelabel_involved_projects' do
    let(:account) { create(:account) }
    let(:whitelabel_mission) { create(:mission, whitelabel: true, whitelabel_domain: 'NOT.test.host') }

    let!(:whitelabel_involved_project) do
      project = create(:project, title: 'Whitelabel Interested Project', mission: whitelabel_mission)
      # project.mission.update(whitelabel: true, whitelabel_domain: 'NOT.test.host')
      create(:project_role, project: project, account: account)
      project
    end

    let!(:whitelabel_uninvolved_project) do
      project = create(:project, title: 'Whiitelabel Uninterested Project', mission: whitelabel_mission)
      # project.mission.update(whitelabel: true, whitelabel_domain: 'NOT.test.host')
      project
    end

    let!(:non_whitelabel_involved_project) do
      project = create(:project, title: 'Non Whitelabel Interested Project')
      create(:project_role, project: project, account: account)
      project
    end

    let!(:non_whitelabel_uninvolved_project) do
      project = create(:project, title: 'Non Whitelabel Uninterested Project') # rubocop:todo Lint/UselessAssignment
    end

    it 'shows just the non-whitelabel interested task with no whitelabel' do
      expect(account.whitelabel_involved_projects(nil)).to eq([non_whitelabel_involved_project])
    end

    it 'shows just the whitelabel interested task with whitelabel' do
      expect(account.whitelabel_involved_projects(whitelabel_mission)).to eq([whitelabel_involved_project])
    end
  end

  describe '.make_everyone_interested' do
    let!(:project) { create :project }
    let!(:users) do
      10.times { create(:account) }
      described_class.all
    end

    it 'loops through all users in batch sizes of 500 and makes them all interested in a project' do
      expect(project.accounts).to contain_exactly(project.account)
      described_class.make_everyone_interested(project)
      expect(project.accounts.to_a).to contain_exactly(*users)
    end
  end

  describe 'populate_managed_account_id' do
    let!(:account) { create(:account) }
    let!(:managed_account) { create(:account, managed_mission: create(:mission)) }

    it 'populates managed_account_id if account is managed' do
      expect(managed_account.managed_account_id).not_to be_nil
    end

    it 'doesnt populate managed_account_id if account is not managed' do
      expect(account.managed_account_id).to be_nil
    end
  end

  describe 'reset_latest_verification' do
    let!(:account) { create(:account) }
    let!(:verification) { create(:verification, account: account) }

    it 'resets latest verification if sensitive info is updated' do
      account.update(first_name: 'new first name')
      expect(account.reload.latest_verification).to be_nil
    end

    it 'doesnt reset latest verification if non-sensitive info is updated' do
      account.update(nickname: 'new nickname')
      expect(account.reload.latest_verification).not_to be_nil
    end
  end

  describe '.migrate_ethereum_wallet_to_ethereum_auth_address' do
    context 'when metamask auth was used' do
      context 'with a valid account' do
        let!(:account) { create(:account, nonce: 0, ethereum_wallet: '0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1') }

        it 'copies ethereum_wallet to ethereum_auth_address' do
          described_class.migrate_ethereum_wallet_to_ethereum_auth_address
          expect(account.reload.ethereum_auth_address).to eq(account.ethereum_wallet)
        end
      end

      context 'with an unfinished account' do
        let!(:account) { create(:account, nonce: 0, email: '0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1@comakery.com', ethereum_wallet: '0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1') }

        it 'does nothing' do
          described_class.migrate_ethereum_wallet_to_ethereum_auth_address
          expect(account.reload.ethereum_auth_address).to be_nil
        end
      end
    end

    context 'when metamask auth wasnt used' do
      let!(:account) { create(:account) }

      it 'does nothing' do
        described_class.migrate_ethereum_wallet_to_ethereum_auth_address
        expect(account.reload.ethereum_auth_address).to be_nil
      end
    end
  end

  describe '#sync_balances_later' do
    let!(:wallet) { create(:wallet) }
    let!(:account) { wallet.account }
    subject { account.sync_balances_later }

    context 'when there are tokens on the same blockchain as wallet' do
      let!(:token) { create(:token, _blockchain: wallet._blockchain) }

      it 'creates a balance record for each token' do
        expect { subject }.to change(account.balances, :count).by(1)
      end

      it 'schedules balances sync' do
        expect_any_instance_of(Balance).to receive(:sync_with_blockchain_later)
        subject
      end
    end
  end

  describe '#address_for_blockchain' do
    let!(:wallet) { create(:wallet) }
    let!(:wallet2) { create(:wallet, address: build(:bitcoin_address_2), account: wallet.account) }
    let!(:account) { wallet.account }
    subject { account.address_for_blockchain(wallet._blockchain) }

    it { is_expected.to eq(wallet.address) }
  end

  describe '#ore_id_address_for_blockchain' do
    let!(:wallet) { create(:ore_id_wallet) }
    let!(:account) { wallet.account }
    subject { account.ore_id_address_for_blockchain(wallet._blockchain) }

    it { is_expected.to eq(wallet.address) }
  end

  describe '#wallets_for_blockchain' do
    let!(:wallet) { create(:wallet) }
    let!(:wallet2) { create(:eth_wallet, account: wallet.account) }
    let!(:account) { wallet.account }
    subject { account.wallets_for_blockchain(wallet._blockchain) }

    it { is_expected.to include(wallet) }
    it { is_expected.not_to include(wallet2) }
  end

  describe '#whitelabel?' do
    subject(:result) { account.whitelabel? }

    context 'when managed mission is present' do
      let(:account) { build(:account, managed_mission: mission) }

      context 'when managed mission whitelabel enabled' do
        let(:mission) { build(:mission, whitelabel: true) }

        it 'should return true' do
          expect(result).to eq true
        end
      end

      context 'when managed mission whitelabel disabled' do
        let(:mission) { build(:mission, whitelabel: false) }

        it 'should return true' do
          expect(result).to eq false
        end
      end
    end

    context 'when managed mission is not present' do
      let(:account) { build(:account) }

      it 'should return false' do
        expect(result).to eq false
      end
    end
  end
end
