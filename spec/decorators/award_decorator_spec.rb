require 'rails_helper'

describe AwardDecorator do
  let!(:team) { create :team }
  let!(:issuer) { create :account, first_name: 'johnny', last_name: 'johnny' }
  let!(:recipient) { create :account, first_name: 'Betty', last_name: 'Ross' }
  let!(:authentication) { create :authentication, account: issuer }
  let!(:project) { create :project, account: issuer, token: create(:token, _token_type: 'eth', _blockchain: :ethereum_ropsten) }
  # let!(:wallet_issuer) { create :wallet, account: issuer, address: '0xD8655aFe58B540D8372faaFe48441AeEc3bec453', _blockchain: project.token._blockchain }
  # let!(:wallet_recipient) { create :wallet, account: recipient, address: '0xD8655aFe58B540D8372faaFe48441AeEc3bec423', _blockchain: project.token._blockchain }
  let!(:award_type) { create :award_type, project: project }
  let!(:award) { create :award, award_type: award_type, issuer: issuer }
  let!(:channel) { create :channel, project: project, team: team, channel_id: 'channel' }

  let(:ethereum_transaction_address) do
    '0xb808727d7968303cdd6486d5f0bdf7c0f690f59c1311458d63bc6a35adcacedb'
  end

  before do
    team.build_authentication_team authentication
  end

  subject { (create :award, award_type: award_type, issuer: issuer, account: recipient).decorate }
  specify { expect(subject.issuer_display_name).to eq('johnny johnny') }
  specify { expect(subject.issuer_user_name).to eq('johnny johnny') }
  specify { expect(subject.issuer_address).to eq('0xD8655aFe58B540D8372faaFe48441AeEc3bec453') }
  specify { expect(subject.recipient_display_name).to eq('Betty Ross') }
  specify { expect(subject.recipient_user_name).to eq('Betty Ross') }
  specify { expect(subject.recipient_address).to eq('0xD8655aFe58B540D8372faaFe48441AeEc3bec423') }

  describe '#ethereum_transaction_address_short' do
    subject(:ethereum_transaction_address_short) do
      award.decorate.ethereum_transaction_address_short
    end

    let(:account) { FactoryBot.create(:account) }
    let(:token) { FactoryBot.create :token }
    let(:project) { FactoryBot.create :project, token: token, account: account }
    let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }
    let(:award) do
      FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                ethereum_transaction_address: ethereum_transaction_address
    end

    it 'should return shortened ethereum transaction address' do
      expect(award.decorate.ethereum_transaction_address_short).to eq '0xb808727d...'
    end
  end

  describe '#ethereum_transaction_explorer_url' do
    subject(:ethereum_transaction_explorer_url) do
      award.decorate.ethereum_transaction_explorer_url
    end

    let(:account) { FactoryBot.create(:account) }
    let(:token) { FactoryBot.create :token }
    let(:project) { FactoryBot.create :project, token: token, account: account }
    let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }
    let(:award) do
      FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                ethereum_transaction_address: ethereum_transaction_address
    end

    it 'should return ethereum transaction explorer url' do
      expect(ethereum_transaction_explorer_url)
        .to match '/tx/0xb808727d7968303cdd6486d5f0bdf7c0f690f59c1311458d63bc6a35adcacedb'
    end

    context 'with qtum' do
      let(:token) { FactoryBot.create :token, _blockchain: 'qtum_test' }

      it 'should return ethereum transaction explorer url' do
        expect(ethereum_transaction_explorer_url)
          .to match '/tx/0xb808727d7968303cdd6486d5f0bdf7c0f690f59c1311458d63bc6a35adcacedb'
      end
    end
  end

  describe '#amount_pretty' do
    subject(:amount_pretty) { award.decorate.amount_pretty }

    context 'with token with decimal places' do
      let(:account) { FactoryBot.create(:account) }
      let(:token) { FactoryBot.create :token, decimal_places: 8 }
      let(:project) { FactoryBot.create :project, token: token, account: account }
      let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }
      let(:award) do
        FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                  amount: 2.34
      end

      it 'should return amount in pretty format' do
        expect(amount_pretty).to eq '2.34000000'
      end
    end

    context 'without token' do
      let(:award) { FactoryBot.build_stubbed :award, amount: 2.34 }

      it 'should return amount in pretty format' do
        expect(amount_pretty).to eq '2'
      end
    end
  end

  describe '#total_amount_pretty' do
    subject(:total_amount_pretty) { award.decorate.total_amount_pretty }

    let(:account) { FactoryBot.create(:account) }
    let(:token) { FactoryBot.create :token, decimal_places: 8 }
    let(:project) { FactoryBot.create :project, token: token, account: account }
    let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }

    context 'with amount 50 and quantity 2.5' do
      let(:award) do
        FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                  amount: 50, quantity: 2.5
      end

      it 'should return formatted total amount' do
        expect(total_amount_pretty).to eq '125.00000000'
      end
    end

    context 'with amount 50 and quantity 25' do
      let(:award) do
        FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                  amount: 50, quantity: 25
      end

      it 'should return formatted total amount' do
        expect(total_amount_pretty).to eq '1,250.00000000'
      end
    end

    context 'with amount 50 and quantity 25 and decimal places 2' do
      let(:token) { FactoryBot.create :token, decimal_places: 2 }
      let(:award) do
        FactoryBot.create :award, project: project, transfer_type: transfer_type, issuer: account,
                                  amount: 50, quantity: 25
      end

      it 'should return formatted total amount' do
        expect(total_amount_pretty).to eq '1,250.00'
      end
    end
  end

  it 'returns part_of_email' do
    award = create :award, quantity: 2.5, email: 'test@test.st'
    expect(award.decorate.part_of_email).to eq 'test@...'
  end

  it 'returns communication_channel' do
    award = create :award, quantity: 2.5, email: 'test@test.st'
    expect(award.decorate.communication_channel).to eq 'Email'

    award = create :award, award_type: award_type, quantity: 1, channel: channel
    expect(award.decorate.communication_channel).to eq channel.name_with_provider
  end

  describe 'total_amount_wei' do
    let!(:amount) { 2 }
    let!(:award_18_decimals) { create(:award, status: :ready, amount: amount) }
    let!(:award_2_decimals) { create(:award, status: :ready, amount: amount) }
    let!(:award_0_decimals) { create(:award, status: :ready, amount: amount) }
    let!(:award_no_token) { create(:award, status: :ready, amount: amount) }

    before do
      award_18_decimals.project.token.update(decimal_places: 18)
      award_2_decimals.project.token.update(decimal_places: 2)
      award_0_decimals.project.token.update(decimal_places: 0)
      award_no_token.project.update(token: nil)
    end

    it 'returns total_amount in Wei based on token decimals' do
      expect(award_18_decimals.decorate.total_amount_wei).to eq(2_000_000_000_000_000_000)
      expect(award_2_decimals.decorate.total_amount_wei).to eq(200)
      expect(award_0_decimals.decorate.total_amount_wei).to eq(2)
      expect(award_no_token.decorate.total_amount_wei).to eq(2)
    end
  end

  describe 'transfer_button_text' do
    let!(:project) { create(:project, token: create(:token, contract_address: '0x8023214bf21b1467be550d9b889eca672355c005', _token_type: :comakery_security_token, _blockchain: :ethereum_ropsten)) }
    let!(:eth_award) { create(:award, status: :accepted, award_type: create(:award_type, project: project)) }
    let!(:mint_award) { create(:award, status: :accepted, transfer_type: project.transfer_types.find_by(name: 'mint'), award_type: create(:award_type, project: project)) }
    let!(:burn_award) { create(:award, status: :accepted, transfer_type: project.transfer_types.find_by(name: 'burn'), award_type: create(:award_type, project: project)) }

    it 'returns text based on transfer type' do
      expect(eth_award.decorate.transfer_button_text).to eq('Pay')
      expect(mint_award.decorate.transfer_button_text).to eq('Mint')
      expect(burn_award.decorate.transfer_button_text).to eq('Burn')
    end
  end

  describe 'transfer_button_state_class' do
    let!(:award_created_not_expired) { create(:blockchain_transaction, status: :created, created_at: 1.year.from_now).blockchain_transactable }
    let!(:award_pending) { create(:blockchain_transaction, status: :pending, tx_hash: '0').blockchain_transactable }
    let!(:award_created_expired) { create(:blockchain_transaction, status: :created, created_at: 1.year.ago).blockchain_transactable }
    let!(:award) { create(:award) }

    it 'returns css class for award with created blockchain_transaction' do
      expect(award_created_not_expired.decorate.transfer_button_state_class).to eq('in-progress--metamask')
    end

    it 'returns css class for award with pending blockchain_transaction' do
      expect(award_pending.decorate.transfer_button_state_class).to eq('in-progress--metamask in-progress--metamask__paid')
    end

    it 'returns nil for award with created and expired blockchain_transaction' do
      expect(award_created_expired.decorate.transfer_button_state_class).to be_nil
    end

    it 'returns nil for award without blockchain_transaction' do
      expect(award.decorate.transfer_button_state_class).to be_nil
    end
  end

  describe '#show_prioritize_button?' do
    let(:award) { tx.blockchain_transactable.decorate }
    let(:hot_wallet_mode) { :auto_sending }

    subject { award.show_prioritize_button? }

    before do
      award.project.update!(hot_wallet_mode: hot_wallet_mode)
    end

    context 'for not created tx' do
      let(:tx) { nil }
      let(:award) { create(:award).decorate }

      it { is_expected.to be true }
    end

    context 'for not created tx and disabled hot wallet mode' do
      let(:tx) { nil }
      let(:award) { create(:award).decorate }
      let(:hot_wallet_mode) { :disabled }

      it { is_expected.to be false }
    end

    context 'for tx with created status' do
      let(:tx) { create(:blockchain_transaction, status: :created) }

      it { is_expected.to be true }
    end

    context 'for tx with pending status' do
      let(:tx) { create(:blockchain_transaction, status: :pending, tx_hash: 'tx hash') }

      it { is_expected.to be false }
    end

    context 'for tx with cancelled status' do
      let(:tx) { create(:blockchain_transaction, status: :cancelled, tx_hash: 'tx hash') }

      it { is_expected.to be true }
    end

    context 'for tx with succeed status' do
      let(:tx) { create(:blockchain_transaction, status: :succeed, tx_hash: 'tx hash') }

      it { is_expected.to be false }
    end

    context 'for tx with failed status' do
      let(:tx) { create(:blockchain_transaction, status: :failed, tx_hash: 'tx hash') }

      it { is_expected.to be false }
    end

    context 'for tx with failed status and hot wallet in manual mode' do
      let(:tx) { create(:blockchain_transaction, status: :failed, tx_hash: 'tx hash') }
      let(:hot_wallet_mode) { :manual_sending }

      it { is_expected.to be true }
    end
  end
end
