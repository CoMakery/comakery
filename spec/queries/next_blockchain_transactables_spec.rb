require 'rails_helper'

describe NextBlockchainTransactables do
  describe '#call' do
    subject { described_class.new(project: project, target: :hot_wallet).call }

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

          context 'ignore mint and burn transfers' do
            let!(:mint_transfer) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, transfer_type: project.transfer_types.find_or_create_by(name: 'mint') }
            let!(:burn_transfer) { FactoryBot.create :award, :with_verified_account, project: project, status: :accepted, transfer_type: project.transfer_types.find_or_create_by(name: 'burn') }

            it 'does not include mint and burn transfers' do
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

        context 'when non validate account' do
          let!(:award1) { FactoryBot.create :award, :with_verification_failed_account, project: project, status: :accepted }
          let!(:award2) { FactoryBot.create :award, :with_verification_failed_account, project: project, status: :accepted }

          it { is_expected.to be_empty }
        end

        context 'when account validation is not exist' do
          let!(:award1) { FactoryBot.create :award, project: project, status: :accepted }
          let!(:award2) { FactoryBot.create :award, project: project, status: :accepted }

          it { is_expected.to be_empty }
        end

        context 'ignore paid awards' do
          let!(:award1) { FactoryBot.create :award, :with_verified_account, project: project, status: :paid }

          it { is_expected.to match_array [award2] }
        end

        context 'with previous blockchain transactions exists' do
          let(:batch_size) { 100 }
          let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :created, blockchain_transactables: award1 }

          it { is_expected.not_to include(award1) }

          context 'return an award if latest blockchain transaction was cancelled' do
            let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :cancelled, blockchain_transactables: award1 }

            it { is_expected.to include(award1) }
          end

          context 'return the same award if previous was created more than 10 minutes ago' do
            let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :created, blockchain_transactables: award1, created_at: 20.minutes.ago }

            it { is_expected.to include(award1) }
          end

          context 'doesnt return awards with lates blockchain_transaction Created less than 10 minutes ago' do
            let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :created, blockchain_transactables: award1, created_at: 1.minute.ago }

            it { is_expected.not_to include(award1) }
          end

          context 'doesnt return awards with latest blockchain_transaction is pending' do
            let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :pending, blockchain_transactables: award1, created_at: 20.minutes.ago }

            it { is_expected.not_to include(award1) }
          end

          context 'doesnt return awards with latest blockchain_transaction is failed' do
            let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :failed, blockchain_transactables: award1, created_at: 20.minutes.ago }

            it { is_expected.not_to include(award1) }
          end
        end
      end

      context 'with hot wallet in manual_sending mode' do
        let(:hot_wallet_mode) { 'manual_sending' }

        context 'without prioritized transfers' do
          it { is_expected.to be_empty }
        end

        context 'with prioritized transfers' do
          let!(:prioritized_award) { FactoryBot.create :award, :with_verification_failed_account, project: project, status: :accepted, prioritized_at: Time.zone.now }

          it 'returns prioritized award' do
            is_expected.to match_array [prioritized_award]
          end
        end

        context 'with batch enabled' do
          let!(:prioritized_award1) { FactoryBot.create :award, project: project, status: :accepted, prioritized_at: Time.zone.now }
          let!(:prioritized_award2) { FactoryBot.create :award, project: project, status: :accepted, prioritized_at: Time.zone.now - 1.minute }
          let(:batch_size) { 100 }

          it 'returns all prioritized transfers' do
            is_expected.to match_array [prioritized_award1, prioritized_award2]
          end
        end

        context 'with batch enabled for unsupported token' do
          let!(:prioritized_award) { FactoryBot.create :award, project: project, status: :accepted, prioritized_at: Time.zone.now }
          let(:batch_size) { 100 }
          let(:token) { FactoryBot.create :token, :ropsten }

          it 'returns the first prioritized transfers only (ignore batch)' do
            is_expected.to match_array [prioritized_award]
          end
        end

        context 'return awards with latest blockchain_transaction is failed' do
          let!(:prioritized_award) { FactoryBot.create :award, project: project, status: :accepted, prioritized_at: Time.zone.now }
          let!(:blockchain_transaction) { FactoryBot.create :blockchain_transaction, :erc20_with_batch, :failed, blockchain_transactables: prioritized_award, created_at: 20.minutes.ago }

          it { is_expected.to include(prioritized_award) }
        end
      end
    end

    context 'with account token records available for transaction' do
      let!(:account_token_record) { create(:account_token_record, token: token) }
      let(:project) { FactoryBot.create :project, token: token, hot_wallet: hot_wallet, hot_wallet_mode: hot_wallet_mode }
      let(:hot_wallet) { build(:wallet, account: nil, source: :hot_wallet, _blockchain: token._blockchain, address: build(:ethereum_address_1)) }
      let(:token) { FactoryBot.create :token, :security_token }
      let(:hot_wallet_mode) { 'auto_sending' }

      context 'without blockchain_transaction' do
        let!(:blockchain_transaction) { nil }

        it { is_expected.to include(account_token_record) }
      end

      context 'return account_token_records with latest blockchain_transaction Cancelled' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, status: :cancelled, blockchain_transactables: account_token_record) }

        it { is_expected.to include(account_token_record) }
      end

      context 'return account_token_records with latest blockchain_transaction Created more than 10 minutes ago' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, blockchain_transactables: account_token_record, created_at: 20.minutes.ago) }

        it { is_expected.to include(account_token_record) }
      end

      context 'doesnt return synced account_token_records without blockchain_transaction' do
        before { account_token_record.synced! }

        it { is_expected.not_to include(account_token_record) }
      end

      context 'doesnt return account_token_records with latest blockchain_transaction Created less than 10 minutes ago' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, blockchain_transactables: account_token_record, created_at: 1.second.ago) }

        it { is_expected.not_to include(account_token_record) }
      end

      context 'doesnt return account_token_records with latest blockchain_transaction Pending' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, status: :pending, blockchain_transactables: account_token_record, tx_hash: '0') }

        it { is_expected.not_to include(account_token_record) }
      end

      context 'doesnt return account_token_records with latest blockchain_transaction Succeed' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, status: :succeed, blockchain_transactables: account_token_record, tx_hash: '0') }

        it { is_expected.not_to include(account_token_record) }
      end

      context 'doesnt return account_token_records with latest blockchain_transaction Failed' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_account_token_record, status: :failed, blockchain_transactables: account_token_record) }

        it { is_expected.not_to include(account_token_record) }
      end
    end

    context 'with transfer rule ready available for transaction' do
      subject { described_class.new(project: project, target: :manual, transactable_classes: [TransferRule]).call }

      let!(:transfer_rule) { create(:transfer_rule, token: token) }
      let(:project) { FactoryBot.create :project, token: token }
      let(:token) { FactoryBot.create :token, :security_token }

      it 'returns transfer_rules without blockchain_transaction' do
        is_expected.to include(transfer_rule)
      end

      context 'return transfer_rules with latest blockchain_transaction Cancelled' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, status: :cancelled, blockchain_transactables: transfer_rule) }

        it { is_expected.to include(transfer_rule) }
      end

      context 'return transfer_rules with latest blockchain_transaction Created more than 10 minutes ago' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, blockchain_transactables: transfer_rule, created_at: 20.minutes.ago) }

        it { is_expected.to include(transfer_rule) }
      end

      context 'doesnt return synced transfer_rules without blockchain_transaction' do
        before { transfer_rule.synced! }

        it { is_expected.not_to include(transfer_rule) }
      end

      context 'doesnt return transfer_rules with latest blockchain_transaction Created less than 10 minutes ago' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, blockchain_transactables: transfer_rule, created_at: 1.minute.ago) }

        it { is_expected.not_to include(transfer_rule) }
      end

      context 'doesnt return transfer_rules with latest blockchain_transaction Pending' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, status: :pending, blockchain_transactables: transfer_rule, tx_hash: '0') }

        it { is_expected.not_to include(transfer_rule) }
      end

      context 'doesnt return transfer_rules with latest blockchain_transaction Succeed' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, status: :succeed, blockchain_transactables: transfer_rule, tx_hash: '0') }

        it { is_expected.not_to include(transfer_rule) }
      end

      context 'return transfer_rules with latest blockchain_transaction Failed' do
        let!(:blockchain_transaction) { create(:blockchain_transaction_transfer_rule, status: :failed, blockchain_transactables: transfer_rule) }

        it { is_expected.to include(transfer_rule) }
      end
    end

    context 'with token as transactable' do
      subject { described_class.new(project: project, target: :manual, transactable_classes: [Token]).call }

      let(:project) { FactoryBot.create :project, token: token }
      let(:token) { FactoryBot.create :token, :security_token }

      it 'returns transfer_rules without blockchain_transaction' do
        is_expected.to include(token)
      end
    end
  end
end
