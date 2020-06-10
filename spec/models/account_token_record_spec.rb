require 'rails_helper'

describe AccountTokenRecord do
  describe 'associations' do
    let!(:token) { create(:token, coin_type: :comakery) }
    let!(:reg_group) { create(:reg_group, token: token) }
    let!(:account) { create(:account) }
    let!(:account_token_record) { create(:account_token_record, token: token, reg_group: reg_group, account: account) }

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
      account_token_record = described_class.new(token: create(:token, coin_type: :comakery))

      expect(account_token_record.lockup_until).not_to be_nil
      expect(account_token_record.reg_group).not_to be_nil
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

    it 'requires balance to be not less than min value' do
      account_token_record = build(:account_token_record, balance: described_class::BALANCE_MIN - 1)
      expect(account_token_record).not_to be_valid
    end

    it 'requires balance to be not greater than max value' do
      account_token_record = build(:account_token_record, balance: described_class::BALANCE_MAX + 1)
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
end
