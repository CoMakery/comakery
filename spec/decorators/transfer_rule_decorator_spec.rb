require 'rails_helper'

RSpec.describe TransferRuleDecorator do
  describe 'form_attrs' do
    subject { transfer_rule.decorate.form_attrs(project) }

    context 'with comakery security token' do
      let(:transfer_rule) { create(:transfer_rule) }
      let(:project) { create(:project, token: transfer_rule.token) }

      it { is_expected.to be_a(Hash) }
    end

    context 'with algorand security token', :vcr do
      let(:transfer_rule) { create(:algo_sec_dummy_transfer_rule) }
      let(:project) { create(:project, token: transfer_rule.token) }

      it { is_expected.to be_a(Hash) }
    end
  end

  describe 'form_attrs_del' do
    subject { transfer_rule.decorate.form_attrs_del(project) }

    context 'with comakery security token' do
      let(:transfer_rule) { create(:transfer_rule) }
      let(:project) { create(:project, token: transfer_rule.token) }

      it { is_expected.to be_a(Hash) }
    end

    context 'with algorand security token', :vcr do
      let(:transfer_rule) { create(:algo_sec_dummy_transfer_rule) }
      let(:project) { create(:project, token: transfer_rule.token) }

      it { is_expected.to be_a(Hash) }
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
