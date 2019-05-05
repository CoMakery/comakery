require 'rails_helper'

describe Award do
  describe 'associations' do
    it 'has the expected associations' do
      described_class.create!(
        name: 'test',
        why: 'test',
        description: 'test',
        requirements: 'test',
        proof_link: 'http://none',
        proof_id: 'xyz123',
        issuer: create(:account),
        account: create(:account),
        award_type: create(:award_type),
        amount: 50,
        quantity: 2
      )
    end
  end

  describe 'scopes' do
    before do
      described_class.statuses.each_key { |status| (create :award).update(status: status) }
    end

    it '.completed returns only accepted and paid awards' do
      described_class.statuses.each_key do |status|
        if %w[accepted paid].include? status
          expect(described_class.completed.pluck(:status).include?(status)).to be_truthy
        else
          expect(described_class.completed.pluck(:status).include?(status)).to be_falsey
        end
      end
    end

    it '.listed returns all but cancelled awards' do
      described_class.statuses.each_key do |status|
        if status == 'cancelled'
          expect(described_class.listed.pluck(:status).include?(status)).to be_falsey
        else
          expect(described_class.listed.pluck(:status).include?(status)).to be_truthy
        end
      end
    end
  end

  describe 'validations' do
    it 'requires things be present' do
      expect(described_class.new(quantity: nil).tap(&:valid?).errors.full_messages).to match_array([
                                                                                                     "Award type can't be blank",
                                                                                                     "Name can't be blank",
                                                                                                     "Why can't be blank",
                                                                                                     "Description can't be blank",
                                                                                                     "Requirements can't be blank",
                                                                                                     "Proof link can't be blank",
                                                                                                     'Proof link must include protocol (e.g. https://)',
                                                                                                     'Amount is not a number',
                                                                                                     'Total amount must be greater than 0'
                                                                                                   ])
    end

    it 'cannot be destroyed unless in ready status' do
      described_class.statuses.keys.each do |status|
        a = create(:award)
        a.update(status: status)
        if status == 'ready'
          expect { a.destroy }.to(change { described_class.count }.by(-1))
        else
          expect { a.destroy }.not_to(change { described_class.count })
          expect(a.errors[:base].first).to eq("#{status.capitalize} task can't be deleted")
        end
      end
    end

    it 'allows only predefined experience levels' do
      [0, 2, 3, 10, 10000].each do |level|
        a = create(:award)
        a.experience_level = level
        if Award::EXPERIENCE_LEVELS.values.include?(level)
          expect(a).to be_valid
        else
          expect(a).not_to be_valid
          expect(a.errors.full_messages.first).to eq('Experience level is not included in the list')
        end
      end
    end

    describe 'awards amounts must be > 0' do
      let(:award) { build :award }

      specify do
        award.quantity = -1
        expect(award.valid?).to eq(false)
        expect(award.errors[:quantity]).to eq(['must be greater than 0'])
      end

      specify do
        award.amount = -1
        expect(award.valid?).to eq(false)
        expect(award.errors[:amount]).to eq(['must be greater than 0'])
      end
    end

    describe 'total_amount should be calculated based on amount and quantity' do
      let(:award) { build :award }

      specify do
        award.quantity = 2
        award.amount = 100
        expect(award.valid?).to eq(true)
        expect(award.total_amount).to eq 200
      end
    end

    describe '#ethereum_transaction_address' do
      let(:project) { create(:project, token: create(:token, coin_type: 'erc20')) }
      let(:award_type) { create(:award_type, project: project) }
      let(:award) { create(:award, award_type: award_type) }
      let(:address) { '0x' + 'a' * 64 }

      it 'validates with a valid ethereum transaction address' do
        expect(build(:award, ethereum_transaction_address: nil)).to be_valid
        expect(build(:award, ethereum_transaction_address: "0x#{'a' * 64}")).to be_valid
        expect(build(:award, ethereum_transaction_address: "0x#{'A' * 64}")).to be_valid
      end

      it 'does not validate with an invalid ethereum transaction address' do
        expected_error_message = "Ethereum transaction address should start with '0x', followed by a 64 character ethereum address"
        expect(award.tap { |o| o.ethereum_transaction_address = 'foo' }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = '0x' }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = "0x#{'a' * 63}" }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = "0x#{'a' * 65}" }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = "0x#{'g' * 64}" }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
      end

      it { expect(award.ethereum_transaction_address).to eq(nil) }

      it 'can be set' do
        award.ethereum_transaction_address = address
        award.save!
        award.reload
        expect(award.ethereum_transaction_address).to eq(address)
      end

      it 'once set cannot be set unset' do
        award.ethereum_transaction_address = address
        award.save!
        award.ethereum_transaction_address = nil
        expect(award).not_to be_valid
        expect(award.errors.full_messages.to_sentence).to match \
          /Ethereum transaction address cannot be changed after it has been set/
      end

      it 'once set it cannot be set to another value' do
        award.ethereum_transaction_address = address
        award.save!
        award.ethereum_transaction_address = '0x' + 'b' * 64
        expect(award).not_to be_valid
        expect(award.errors.full_messages.to_sentence).to match \
          /Ethereum transaction address cannot be changed after it has been set/
      end
    end

    describe '#ethereum_transaction_address on qtum network' do
      let(:project) { create(:project, token: create(:token, coin_type: 'qrc20')) }
      let(:award_type) { create(:award_type, project: project) }
      let(:award) { create(:award, award_type: award_type) }
      let(:address) { 'a' * 64 }

      it 'validates with a valid ethereum transaction address' do
        expect(build(:award, ethereum_transaction_address: nil)).to be_valid
        expect(build(:award, ethereum_transaction_address: ('a' * 64).to_s)).to be_valid
        expect(build(:award, ethereum_transaction_address: ('A' * 64).to_s)).to be_valid
      end

      it 'does not validate with an invalid ethereum transaction address' do
        expected_error_message = "Ethereum transaction address should have 64 characters, should not start with '0x'"
        expect(award.tap { |o| o.ethereum_transaction_address = 'foo' }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = "0x#{'a' * 62}" }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = ('a' * 65).to_s }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
        expect(award.tap { |o| o.ethereum_transaction_address = ('g' * 64).to_s }.tap(&:valid?).errors.full_messages).to eq([expected_error_message])
      end

      it { expect(award.ethereum_transaction_address).to eq(nil) }

      it 'can be set' do
        award.ethereum_transaction_address = address
        award.save!
        award.reload
        expect(award.ethereum_transaction_address).to eq(address)
      end

      it 'once set cannot be set unset' do
        award.ethereum_transaction_address = address
        award.save!
        award.ethereum_transaction_address = nil
        expect(award).not_to be_valid
        expect(award.errors.full_messages.to_sentence).to match \
          /Ethereum transaction address cannot be changed after it has been set/
      end

      it 'once set it cannot be set to another value' do
        award.ethereum_transaction_address = address
        award.save!
        award.ethereum_transaction_address = 'b' * 64
        expect(award).not_to be_valid
        expect(award.errors.full_messages.to_sentence).to match \
          /Ethereum transaction address cannot be changed after it has been set/
      end
    end
  end

  describe '#total_amount should no be round' do
    specify do
      award = create :award, quantity: 1.4, amount: 1
      award.reload
      expect(award.total_amount).to eq(0.14e1)
    end

    specify do
      award = create :award, quantity: 1.5, amount: 1
      award.reload
      expect(award.total_amount).to eq(0.15e1)
    end
  end

  describe '.total_awarded' do
    describe 'without project awards' do
      specify { expect(described_class.total_awarded).to eq(0) }
    end

    describe 'with project awards' do
      let!(:project1) { create :project, token: create(:token, coin_type: 'erc20') }
      let!(:project1_award_type) { (create :award_type, project: project1) }
      let(:project2) { create :project, token: create(:token, coin_type: 'erc20') }
      let!(:project2_award_type) { (create :award_type, project: project2) }
      let(:account) { create :account }

      before do
        create(:award, award_type: project1_award_type, quantity: 5, amount: 3, issuer: project1.account, account: account)
        create(:award, award_type: project1_award_type, quantity: 5, amount: 3, issuer: project1.account, account: account)

        create(:award, award_type: project2_award_type, quantity: 3, amount: 5, issuer: project2.account, account: account)
        create(:award, award_type: project2_award_type, quantity: 7, amount: 5, issuer: project2.account, account: account)
      end

      it 'is able to scope to a project' do
        expect(project1.awards.total_awarded).to eq(30)
        expect(project2.awards.total_awarded).to eq(50)
      end

      it 'returns the total amount of awards issued' do
        expect(described_class.total_awarded).to eq(80)
      end
    end
  end

  describe 'helper methods' do
    let!(:team) { create :team }
    let!(:team1) { create :team, provider: 'discord' }
    let!(:account) { create :account, email: 'reciver@test.st' }
    let!(:authentication) { create :authentication, account: account }
    let!(:account1) { create :account }
    let!(:authentication1) { create :authentication, account: account1, provider: 'discord' }
    let!(:project) { create :project, account: account, token: create(:token, coin_type: 'erc20') }
    let!(:award_type) { (create :award_type, project: project) }
    let!(:award) { create :award, award_type: award_type, amount: 3, issuer: account, account: account }
    let!(:award1) { create :award, award_type: award_type, amount: 3, issuer: account, account: account1 }

    before do
      team.build_authentication_team authentication
      team1.build_authentication_team authentication1
      stub_discord_channels
      project.channels.create(team: team1, channel_id: 'general')
    end

    it 'check for ethereum issue ready' do
      expect(award.ethereum_issue_ready?).to be_falsey

      project.token.update ethereum_enabled: true
      account.update ethereum_wallet: '0xD8655aFe58B540D8372faaFe48441AeEc3bec423'

      expect(award.reload.ethereum_issue_ready?).to be_truthy
    end
    it 'check self_issued award' do
      expect(award.self_issued?).to be_truthy
      expect(award1.self_issued?).to be_falsey
    end

    it 'check discord award' do
      expect(award.discord?).to be_falsey
      expect(award1.discord?).to be_falsey
      award1.update channel_id: project.channels.last.id
      expect(award1.reload.discord?).to be_truthy
    end

    it 'round total_amount' do
      award.amount = 2.2
      award.save
      expect(award.reload.total_amount).to eq 0.22e1
    end

    it 'return recipient_auth_team' do
      auth_team = account1.authentication_teams.last
      award1.channel = project.channels.last
      award1.save
      expect(award.recipient_auth_team).to be_nil
      expect(award1.recipient_auth_team).to eq auth_team
    end

    it 'send send_confirm_email' do
      award.update email: 'reciver@test.st'
      expect { award.send_confirm_email }.to change { ActionMailer::Base.deliveries.count }.by(1)
      award.update confirm_token: '1234'
      expect { award.send_confirm_email }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end

    it 'confirm award' do
      award.update email: 'reciver@test.st', confirm_token: '1234'
      award.confirm!(account1)
      award.reload
      expect(award.account).to eq account1
      expect(award.confirmed?).to eq true
    end
  end

  describe '#send_award_notifications' do
    let!(:team) { create :team }
    let!(:account) { create :account }
    let!(:authentication) { create :authentication, account: account }
    let!(:discord_team) { create :team, provider: 'discord' }
    let!(:project) { create :project, account: account, token: create(:token, coin_type: 'erc20') }
    let!(:award_type) { create :award_type, project: project }
    let!(:channel) { create :channel, team: team, project: project, channel_id: 'channel_id', name: 'channel_id' }
    let!(:account1) { create :account }
    let!(:authentication1) { create :authentication, account: account1 }
    let!(:award) { create :award, award_type: award_type, issuer: account, channel: channel, account: account1 }

    let!(:message) { AwardMessage.call(award: award).notifications_message }

    before do
      team.build_authentication_team authentication
    end

    it 'sends a Slack notification' do
      # allow(award.slack_client).to receive(:send_award_notifications)
      message = AwardMessage.call(award: award).notifications_message
      token = authentication1.token
      stub_request(:post, 'https://slack.com/api/chat.postMessage').with(body: hash_including(text: message,
                                                                                              token: token,
                                                                                              channel: "##{channel.name}",
                                                                                              username: / Bot/,
                                                                                              icon_url: Comakery::Slack::AVATAR,
                                                                                              as_user: 'false',
                                                                                              link_names: '1')).to_return(body: {
                                                                                                ok: true,
                                                                                                channel: 'channel id',
                                                                                                message: { ts: 'this is a timestamp' }
                                                                                              }.to_json)
      stub_request(:post, 'https://slack.com/api/reactions.add').with(body: hash_including(channel: 'channel id',
                                                                                           timestamp: 'this is a timestamp',
                                                                                           name: 'thumbsup')).to_return(body: { ok: true }.to_json)
      award.send_award_notifications
    end

    it 'sends a Discord notification' do
      stub_discord_channels
      channel = project.channels.create(team: discord_team, channel_id: 'channel_id', name: 'discord_channel')
      award = create :award, award_type: award_type, amount: 3, issuer: account, channel: channel
      allow(award.discord_client).to receive(:send_message)
      award.send_award_notifications
      expect(award.discord_client).to have_received(:send_message)
    end
  end
end
