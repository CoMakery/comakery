require 'rails_helper'

describe NextBlockchainTransactables do
  describe '#call' do
    subject { described_class.new(project: project, target: { for: :hot_wallet }, verified_accounts_only: verified_accounts_only).call }
    let(:verified_accounts_only) { true }

    context 'with awards available for transaction' do
      let!(:award1) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted }
      let!(:award2) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted }
      let(:project) { FactoryBot.create :project, transfer_batch_size: batch_size, token: token, hot_wallet: hot_wallet, hot_wallet_mode: hot_wallet_mode }
      let(:token) { FactoryBot.create :token, :erc20_with_batch }
      let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: token._blockchain, address: build(:ethereum_address_1)) }
      let(:batch_size) { 1 }

      context 'when hot wallet is disabled' do
        let(:hot_wallet_mode) { 'disabled' }

        it { is_expected.to be_empty }
      end

      context 'with hot wallet in auto_sending mode' do
        let(:hot_wallet_mode) { 'auto_sending' }

        it 'returns the first transfer' do
          is_expected.to match_array [award1]
        end

        context 'with batch enabled' do
          let(:batch_size) { 100 }

          it 'returns all exist transfers' do
            is_expected.to match_array [award1, award2]
          end

          context 'with lockup_token w/o batch_contract_address' do
            let!(:award1) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, lockup_schedule_id: 0, commencement_date: Time.zone.now }
            let!(:award2) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, lockup_schedule_id: 0, commencement_date: Time.zone.now }
            let(:token) { FactoryBot.create :token, :lockup, batch_contract_address: nil }

            it 'returns all exist transfers' do
              is_expected.to match_array [award1, award2]
            end
          end
        end

        context 'with batch enabled for unsupported token' do
          let(:batch_size) { 100 }
          let(:token) { FactoryBot.create :token, :ropsten }

          it 'returns the first transfers only (ignore batch)' do
            is_expected.to match_array [award1]
          end
        end

        context 'when prioritized transfer exists' do
          let!(:prioritized_award) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, prioritized_at: Time.zone.now }

          it 'returns prioritized transfer' do
            is_expected.to match_array [prioritized_award]
          end
        end

        context 'when verified_accounts_only = false' do
          let(:verified_accounts_only) { false }

          it 'returns transfer' do
            is_expected.to match_array [award1]
          end
        end

        context 'when non validate account' do
          let!(:award1) { FactoryBot.create :award, :with_unverified_account, project: project, status: :accepted }
          let!(:award2) { FactoryBot.create :award, :with_unverified_account, project: project, status: :accepted }

          it { is_expected.to be_empty }
        end

        context 'when account validation is not exist' do
          let!(:award1) { FactoryBot.create :award, project: project, status: :accepted }
          let!(:award2) { FactoryBot.create :award, project: project, status: :accepted }

          it { is_expected.to be_empty }
        end
      end

      context 'with hot wallet in manual_sending mode' do
        let(:hot_wallet_mode) { 'manual_sending' }

        context 'without prioritized transfers' do
          it { is_expected.to be_empty }
        end

        context 'with prioritized transfers' do
          let!(:prioritized_award) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, prioritized_at: Time.zone.now }

          it 'returns prioritized award' do
            is_expected.to match_array [prioritized_award]
          end
        end

        context 'with batch enabled' do
          let!(:prioritized_award1) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, prioritized_at: Time.zone.now }
          let!(:prioritized_award2) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, prioritized_at: Time.zone.now - 1.minute }
          let(:batch_size) { 100 }

          it 'returns all prioritized transfers' do
            is_expected.to match_array [prioritized_award1, prioritized_award2]
          end
        end

        context 'with batch enabled for unsupported token' do
          let!(:prioritized_award) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, prioritized_at: Time.zone.now }
          let(:batch_size) { 100 }
          let(:token) { FactoryBot.create :token, :ropsten }

          it 'returns the first prioritized transfers only (ignore batch)' do
            is_expected.to match_array [prioritized_award]
          end
        end
      end
    end
  end
end
