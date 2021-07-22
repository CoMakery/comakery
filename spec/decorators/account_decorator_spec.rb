require 'rails_helper'

describe AccountDecorator do
  subject(:account) { create :account, password: '12345678' }

  before do
    stub_discord_channels
  end

  describe '#name' do
    it 'returns the first and last name and falls back to the user name' do
      expect(build(:account, first_name: 'Bob', last_name: 'Johnson').decorate.name).to eq('Bob Johnson')
      expect(build(:account, first_name: nil, last_name: 'Johnson').decorate.name).to eq('Johnson')
      expect(build(:account, first_name: 'Bob', last_name: '').decorate.name).to eq('Bob')
    end
  end

  describe '#nick' do
    it 'returns the nickname and falls back to the name' do
      expect(build(:account, first_name: 'Bob', last_name: 'Johnson', nickname: nil).decorate.nick).to eq('Bob Johnson')
      expect(build(:account, first_name: nil, last_name: 'Johnson', nickname: nil).decorate.nick).to eq('Johnson')
      expect(build(:account, first_name: 'Bob', last_name: '', nickname: nil).decorate.nick).to eq('Bob')
      expect(build(:account, first_name: 'Bob', last_name: 'Johnson', nickname: 'bobjon').decorate.nick).to eq('bobjon')
    end
  end

  describe '#avatar_tag' do
    subject { create(:account).decorate.avatar_tag }

    it { is_expected.to include("class='avatar avatar-xs'") }
  end

  describe '#name_with_nickname' do
    it 'combines name and nickname' do
      expect(build(:account, first_name: 'Bob', last_name: 'Johnson', nickname: 'bobjon').decorate.name_with_nickname).to eq('Bob Johnson (bobjon)')
    end

    it 'returns only name if nickname is not present' do
      expect(build(:account, first_name: 'Bob', last_name: 'Johnson', nickname: nil).decorate.name_with_nickname).to eq('Bob Johnson')
    end
  end

  describe '#can_send_awards?' do
    let!(:project) { create :project }
    let!(:project2) { create :project }

    context 'when account is project owner or admin' do
      it 'can send awards' do
        project.project_admins << project2.account

        expect(project.account.decorate.can_send_awards?(project)).to be true
        expect(project2.account.decorate.can_send_awards?(project)).to be true
      end
    end

    context 'when account is not project owner or admin' do
      it 'cannot send awards' do
        expect(project2.account.decorate.can_send_awards?(project)).to be false
      end
    end
  end

  describe '#can_receive_awards?' do
    let!(:wallet) { create(:wallet, address: '0x' + '0' * 40, _blockchain: :ethereum_ropsten) }
    let!(:project) { build :project, token: create(:token, _token_type: 'eth', _blockchain: :ethereum_ropsten) }

    context 'when wallet for project token blockchain is present' do
      it 'returns true' do
        expect(wallet.account.decorate.can_receive_awards?(project)).to be true
      end
    end

    context 'when wallet for project token blockchain is not present' do
      it 'returns false' do
        expect(create(:wallet).account.decorate.can_receive_awards?(project)).to be_falsey
      end
    end

    context 'when project token is not present' do
      it 'returns false' do
        project.token = nil
        expect(wallet.account.decorate.can_receive_awards?(project)).to be_falsey
      end
    end
  end

  describe 'image_url' do
    let!(:account_w_image) { create(:account, image: dummy_image) }
    let!(:account_wo_image) { create :account }

    it 'returns image_url if present' do
      expect(account_w_image.decorate.image_url).to include('dummy_image')
    end

    it 'returns default image' do
      expect(account_wo_image.decorate.image_url).to include('user-icon')
    end
  end

  describe 'wallet_address_link_for' do
    let!(:account_w_eth_wallet) { create(:wallet, _blockchain: :ethereum, address: '0x3551cd3a70e07b3484f20d9480e677243870d67e').account }
    let!(:account_w_btc_wallet) { create(:wallet, _blockchain: :bitcoin_test, address: 'msb86hf6ssyYkAJ8xqKUjmBEkbW3cWCdps').account }
    let!(:account_wo_wallet) { create(:account) }
    let!(:project_w_token) { create :project, token: create(:token, _token_type: 'eth', _blockchain: :ethereum) }
    let!(:project_wo_token) { create :project, token: nil }
    let!(:project_w_token_on_bitcoin_testnet) { create :project, token: create(:token, _token_type: :btc, _blockchain: :bitcoin_test) }

    it 'returns link for wallet address if account has address for project token' do
      expect(account_w_eth_wallet.decorate.wallet_address_link_for(project_w_token)).to include(account_w_eth_wallet.address_for_blockchain(:ethereum))
    end

    it 'returns placeholder if account doesnt have address for project token' do
      expect(account_w_eth_wallet.decorate.wallet_address_link_for(project_wo_token)).to eq('needs wallet')
      expect(account_wo_wallet.decorate.wallet_address_link_for(project_wo_token)).to eq('needs wallet')
      expect(account_wo_wallet.decorate.wallet_address_link_for(project_w_token)).to eq('needs wallet')
    end

    it 'returns link with correct network' do
      expect(account_w_btc_wallet.decorate.wallet_address_link_for(project_w_token_on_bitcoin_testnet)).to include('btc-testnet')
    end
  end

  describe 'verification_state' do
    let(:passed_account) { create(:account, unverified: true) }
    let(:failed_account) { create(:account, unverified: true) }
    let(:unknown_account) { create(:account, unverified: true) }

    it 'returns passed for passed_account' do
      create(:verification, account: passed_account, passed: true)
      expect(passed_account.reload.decorate.verification_state).to eq('passed')
    end

    it 'returns failed for failed_account' do
      create(:verification, account: failed_account, passed: false)
      expect(failed_account.reload.decorate.verification_state).to eq('failed')
    end

    it 'returns unknown for unknown_account' do
      expect(unknown_account.reload.decorate.verification_state).to eq('unknown')
    end
  end

  describe 'verification_date' do
    let!(:passed_account) { create(:account) }
    let!(:unknown_account) { create(:account, unverified: true) }

    it 'returns date for passed_account' do
      create(:verification, account: passed_account, passed: true)
      expect(passed_account.reload.decorate.verification_date).not_to be_nil
    end

    it 'returns nil for unknown_account' do
      expect(unknown_account.reload.decorate.verification_date).to be_nil
    end
  end

  describe 'verification_max_investment_usd' do
    let!(:passed_account) { create(:account) }
    let!(:unknown_account) { create(:account, unverified: true) }

    it 'returns max_investment_usd for passed_account' do
      max_investment_usd = 100

      create(:verification, account: passed_account, passed: true, max_investment_usd: max_investment_usd)
      expect(passed_account.reload.decorate.verification_max_investment_usd).to eq(max_investment_usd)
    end

    it 'returns nil for unknown_account' do
      expect(unknown_account.reload.decorate.verification_max_investment_usd).to be_nil
    end
  end

  describe 'total_received_in' do
    let!(:account) { create(:account) }
    let!(:token) { create(:token) }
    let!(:token2) { create(:token) }
    let!(:award_type) { create(:award_type, project: create(:project, token: token)) }
    let!(:award_type2) { create(:award_type, project: create(:project, token: token2)) }

    before do
      create(:award, account: account, status: :paid, amount: 1, award_type: award_type)
      create(:award, account: account, status: :paid, amount: 2, award_type: award_type)
      create(:award, account: account, status: :rejected, amount: 4, award_type: award_type)
      create(:award, account: account, status: :paid, amount: 8, award_type: award_type2)
    end

    it 'sums up total_amounts of account paid tasks from projects using given token' do
      expect(account.decorate.total_received_in(token)).to eq(3)
    end
  end

  describe 'total_accepted_in' do
    let!(:account) { create(:account) }
    let!(:token) { create(:token) }
    let!(:token2) { create(:token) }
    let!(:award_type) { create(:award_type, project: create(:project, token: token)) }
    let!(:award_type2) { create(:award_type, project: create(:project, token: token2)) }

    before do
      create(:award, account: account, status: :accepted, amount: 1, award_type: award_type)
      create(:award, account: account, status: :accepted, amount: 2, award_type: award_type)
      create(:award, account: account, status: :rejected, amount: 4, award_type: award_type)
      create(:award, account: account, status: :accepted, amount: 8, award_type: award_type2)
    end

    it 'sums up total_amounts of account accepted tasks from projects using given token' do
      expect(account.decorate.total_accepted_in(token)).to eq(3)
    end
  end

  describe 'total_received_and_accepted_in' do
    let!(:account) { create(:account) }
    let!(:token) { create(:token) }
    let!(:token2) { create(:token) }
    let!(:award_type) { create(:award_type, project: create(:project, token: token)) }
    let!(:award_type2) { create(:award_type, project: create(:project, token: token2)) }

    before do
      create(:award, account: account, status: :accepted, amount: 1, award_type: award_type)
      create(:award, account: account, status: :paid, amount: 2, award_type: award_type)
      create(:award, account: account, status: :rejected, amount: 4, award_type: award_type)
      create(:award, account: account, status: :accepted, amount: 8, award_type: award_type2)
    end

    it 'sums up total_amounts of account accepted and paid tasks from projects using given token' do
      expect(account.decorate.total_received_and_accepted_in(token)).to eq(3)
    end
  end
end
