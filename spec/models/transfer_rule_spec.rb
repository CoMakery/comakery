require 'rails_helper'
require 'models/concerns/refreshable_spec'

describe TransferRule do
  it_behaves_like 'refreshable'

  describe 'associations' do
    let!(:token) { create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten) }
    let!(:sending_group) { create(:reg_group, token: token) }
    let!(:receiving_group) { create(:reg_group, token: token) }
    let!(:transfer_rule) { create(:transfer_rule, token: token, sending_group: sending_group, receiving_group: receiving_group) }

    it 'belongs to token' do
      expect(transfer_rule.token).to eq(token)
    end

    it 'belongs to sending_group' do
      expect(transfer_rule.sending_group).to eq(sending_group)
    end

    it 'belongs to receiving_group' do
      expect(transfer_rule.receiving_group).to eq(receiving_group)
    end
  end

  describe 'callbacks' do
    it 'sets default values' do
      transfer_rule = described_class.new

      expect(transfer_rule.lockup_until).not_to be_nil
    end
  end

  describe 'validations' do
    it 'requires comakery token' do
      transfer_rule = create(:transfer_rule)
      transfer_rule.token = create(:token)
      expect(transfer_rule).not_to be_valid
    end

    it 'requires sending_group to belong to same token' do
      sending_group = create(:reg_group)
      transfer_rule = build(:transfer_rule, sending_group: sending_group)
      expect(transfer_rule).not_to be_valid
    end

    it 'requires receiving_group to belong to same token' do
      receiving_group = create(:reg_group)
      transfer_rule = build(:transfer_rule, receiving_group: receiving_group)
      expect(transfer_rule).not_to be_valid
    end

    it 'requires lockup_until to be not less than min value' do
      transfer_rule = build(:transfer_rule, lockup_until: described_class::LOCKUP_UNTIL_MIN - 1)
      expect(transfer_rule).not_to be_valid
    end

    it 'requires lockup_until to be not greater than max value' do
      transfer_rule = build(:transfer_rule, lockup_until: described_class::LOCKUP_UNTIL_MAX + 1)
      expect(transfer_rule).not_to be_valid
    end
  end

  describe 'lockup_until' do
    let!(:max_uint256) { 115792089237316195423570985008687907853269984665640564039458 }
    let!(:transfer_rule) { create(:transfer_rule, lockup_until: Time.zone.at(max_uint256)) }

    it 'stores Time as a high precision decimal (which able to fit uint256) and returns Time object initialized from decimal' do
      expect(transfer_rule.reload.lockup_until).to eq(Time.zone.at(max_uint256))
    end
  end

  describe 'replace_existing_rule' do
    let!(:transfer_rule) { create(:transfer_rule) }
    let!(:transfer_rule_dup) { create(:transfer_rule, token: transfer_rule.token, sending_group: transfer_rule.sending_group, receiving_group: transfer_rule.receiving_group, status: :synced) }
    let!(:transfer_rule_dup_token) { create(:transfer_rule, token: transfer_rule.token, status: :synced) }

    context 'when status synced' do
      before do
        transfer_rule.synced!
      end

      it 'deletes all synced rules with the same combination of token, receiving/sending groups' do
        expect { transfer_rule_dup.reload }.to raise_error ActiveRecord::RecordNotFound
      end

      it 'doesnt delete rules with same token but different receiving/sending groups' do
        expect { transfer_rule_dup_token.reload }.not_to raise_error
      end
    end

    context 'when status not synced' do
      it 'does nothing' do
        expect { transfer_rule.reload }.not_to raise_error
        expect { transfer_rule_dup.reload }.not_to raise_error
        expect { transfer_rule_dup_token.reload }.not_to raise_error
      end
    end
  end
end
