require 'rails_helper'

RSpec.describe TransferRuleDecorator do
  describe 'eth_data' do
    let!(:transfer_rule) { create(:transfer_rule) }

    it 'returns data for transfer-rule-form_controller.js' do
      data = transfer_rule.decorate.eth_data

      expect(data['transfer-rule-form-rule-from-group-id']).to eq(transfer_rule.sending_group.id)
      expect(data['transfer-rule-form-rule-to-group-id']).to eq(transfer_rule.receiving_group.id)
      expect(data['transfer-rule-form-rule-from-group-blockchain-id']).to eq(transfer_rule.sending_group.blockchain_id)
      expect(data['transfer-rule-form-rule-to-group-blockchain-id']).to eq(transfer_rule.receiving_group.blockchain_id)
      expect(data['transfer-rule-form-rule-lockup-until']).to eq(transfer_rule.lockup_until.strftime('%b %e, %Y'))
    end
  end

  describe 'lockup_until_pretty' do
    let!(:transfer_rule_max_lockup) { create(:transfer_rule, lockup_until: 101.years.from_now) }
    let!(:transfer_rule_min_lockup) { create(:transfer_rule, lockup_until: TransferRule::LOCKUP_UNTIL_MIN) }
    let!(:transfer_rule_min_plus_one_lockup) { create(:transfer_rule, lockup_until: TransferRule::LOCKUP_UNTIL_MIN + 1) }
    let!(:transfer_rule) { create(:transfer_rule) }

    it 'returns "> 100 years" if value is more than 100 years from now' do
      expect(transfer_rule_max_lockup.decorate.lockup_until_pretty).to eq('> 100 years')
    end

    it 'returns "∞" if value is min' do
      expect(transfer_rule_min_lockup.decorate.lockup_until_pretty).to eq('∞')
    end

    it 'returns "none" if value is min + 1' do
      expect(transfer_rule_min_plus_one_lockup.decorate.lockup_until_pretty).to eq('None')
    end

    it 'returns formatted date' do
      expect(transfer_rule.decorate.lockup_until_pretty).to eq(transfer_rule.lockup_until.strftime('%b %e, %Y'))
    end
  end
end