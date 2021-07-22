require 'rails_helper'
require 'models/concerns/refreshable_spec'

describe AccountTokenRecord do
  it_behaves_like 'refreshable'

  describe 'associations' do
    let(:token) { create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten) }
    let(:reg_group) { create(:reg_group, token: token) }
    let(:account) { create(:account) }
    let(:wallet) { create(:wallet, address: build(:ethereum_contract_address), account: account, _blockchain: token._blockchain) }
    let!(:account_token_record) { create(:account_token_record, token: token, reg_group: reg_group, account: account, wallet: wallet) }

    it 'belongs to token' do
      expect(account_token_record.token).to eq(token)
    end

    it 'belongs to account' do
      expect(account_token_record.account).to eq(account)
    end

    it 'belongs to reg_group' do
      expect(account_token_record.reg_group).to eq(reg_group)
    end
  end

  describe 'callbacks' do
    it 'sets default values' do
      account_token_record = described_class.new(token: create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten))

      expect(account_token_record.lockup_until).not_to be_nil
      expect(account_token_record.reg_group).not_to be_nil
    end

    it 'sets a wallet on before_validation' do
      account_token_record = build(:account_token_record)
      account_token_record.wallet = nil
      account_token_record.valid?

      expect(account_token_record.wallet).to eq account_token_record.account.wallets.first
    end
  end

  describe 'validations' do
    it 'requires comakery token' do
      account_token_record = create(:account_token_record)
      account_token_record.token = create(:token)
      expect(account_token_record).not_to be_valid
    end

    it 'requires lockup_until to be not less than min value' do
      account_token_record = build(:account_token_record, lockup_until: described_class::LOCKUP_UNTIL_MIN - 1)
      expect(account_token_record).not_to be_valid
    end

    it 'requires lockup_until to be not greater than max value' do
      account_token_record = build(:account_token_record, lockup_until: described_class::LOCKUP_UNTIL_MAX + 1)
      expect(account_token_record).not_to be_valid
    end

    it 'requires max_balance to be present' do
      account_token_record = build(:account_token_record)
      account_token_record.max_balance = nil
      expect(account_token_record).not_to be_valid
    end

    it 'requires max_balance to be not less than min value' do
      account_token_record = build(:account_token_record, max_balance: described_class::BALANCE_MIN - 1)
      expect(account_token_record).not_to be_valid
    end

    it 'requires max_balance to be not greater than max value' do
      account_token_record = build(:account_token_record, max_balance: described_class::BALANCE_MAX + 1)
      expect(account_token_record).not_to be_valid
    end
  end

  describe 'lockup_until' do
    let!(:max_uint256) { 115792089237316195423570985008687907853269984665640564039458 }
    let!(:account_token_record) { create(:account_token_record, lockup_until: Time.zone.at(max_uint256)) }

    it 'stores Time as a high precision decimal (which able to fit uint256) and returns Time object initialized from decimal' do
      expect(account_token_record.reload.lockup_until).to eq(Time.zone.at(max_uint256))
    end
  end

  describe 'replace_existing_record' do
    let!(:account_token_record) { create(:account_token_record) }
    let!(:account_token_record_dup) { create(:account_token_record, token: account_token_record.token, account: account_token_record.account, status: :synced) }
    let!(:account_token_record_dup_account) { create(:account_token_record, account: account_token_record.account, status: :synced) }

    context 'when status synced' do
      before do
        account_token_record.synced!
      end

      it 'deletes all synced records with the same combination of token and account' do
        expect { account_token_record_dup.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'doesnt delete records with same account but different token' do
        expect { account_token_record_dup_account.reload }.not_to raise_error
      end
    end

    context 'when status not synced' do
      it 'does nothing' do
        expect { account_token_record.reload }.not_to raise_error
        expect { account_token_record_dup.reload }.not_to raise_error
        expect { account_token_record_dup_account.reload }.not_to raise_error
      end
    end
  end

  describe '#balance' do
    let(:account_token_record) { create(:account_token_record) }
    subject { account_token_record.balance }

    context 'with no balance created' do
      it 'creates a balance' do
        expect(SyncBalanceJob).to receive(:set).and_call_original
        expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).and_call_original

        is_expected.to be_a Balance
        balance = Balance.last
        expect(balance.wallet).to eq account_token_record.wallet
        expect(balance.token).to eq account_token_record.token
      end
    end

    context 'with a balance created' do
      it 'returns created balance' do
        expect(SyncBalanceJob).to receive(:set).and_call_original
        expect_any_instance_of(ActiveJob::ConfiguredJob).to receive(:perform_later).and_call_original

        balance = create(:balance, wallet: account_token_record.wallet, token: account_token_record.token)
        is_expected.to eq balance
      end
    end
  end
end
