require 'rails_helper'
require 'controllers/concerns/ore_id_callbacks_spec'

RSpec.describe Sign::UserWalletController, type: :controller, vcr: true do
  it_behaves_like 'having ore_id_callbacks'

  let(:transaction) { create(:blockchain_transaction) }
  let(:transfer) { create(:blockchain_transaction).blockchain_transactable }
  let(:account_token_record) { create(:algo_sec_dummy_restrictions) }
  let(:token) { create(:algo_sec_token) }
  let(:transfer_rule) { create(:transfer_rule, token: token) }

  before do
    login(transfer.project.account)
  end

  describe 'GET /new' do
    before do
      allow_any_instance_of(AwardPolicy).to receive(:pay?).and_return(true)
      allow_any_instance_of(described_class).to receive(:sign_url).and_return('/dummy_sign_url')
    end

    context 'with transfer' do
      subject { get :new, params: { transfer_id: transfer.id, source: 'dummy_source_address' } }

      render_views

      it 'creates a correct BlockchainTransaction' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionAward)
      end

      it 'populates source' do
        subject
        expect(BlockchainTransaction.last.source).to eq('dummy_source_address')
      end

      it 'returns json' do
        subject
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to include('tx')
        expect(JSON.parse(response.body)).to include('state')
      end
    end

    context 'with batch transfer' do
      let(:transfer) { create(:blockchain_transaction_lockup).blockchain_transactable }

      subject { get :new, params: { project_id: transfer.project.id, source: 'dummy_source_address' } }

      before do
        transfer.project.update(transfer_batch_size: 100)
        transfer.latest_blockchain_transaction.cancelled!
        transfer.clone_on_assignment
      end

      example 'creates a correct BlockchainTransaction and sets transactables' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionAward)
        expect(BlockchainTransaction.last.blockchain_transactables.size).to eq(2)
      end
    end

    context 'with account token record' do
      subject { get :new, params: { account_token_record_id: account_token_record.id, source: 'dummy_source_address' } }

      it 'creates a correct BlockchainTransaction' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionAccountTokenRecord)
      end
    end

    context 'with transfer rule' do
      subject { get :new, params: { transfer_rule_id: transfer_rule.id, source: 'dummy_source_address' } }

      it 'creates a correct BlockchainTransaction' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionTransferRule)
      end
    end

    context 'with a token' do
      subject { get :new, params: { token_id: token.id, source: 'dummy_source_address' } }

      it 'creates a correct BlockchainTransaction' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionTokenFreeze)
      end
    end

    context 'with a frozen token' do
      subject { get :new, params: { token_id: token.id, source: 'dummy_source_address' } }
      before { token.update(token_frozen: true) }

      it 'creates a correct BlockchainTransaction' do
        subject
        expect(BlockchainTransaction.last).to be_a(BlockchainTransactionTokenUnfreeze)
      end
    end
  end

  describe 'GET /receive' do
    let(:current_ore_id_account) { create(:ore_id) }

    context 'with correct callback' do
      before do
        expect_any_instance_of(described_class).to receive(:verify_errorless).exactly(1).times.and_return(true)
        expect_any_instance_of(described_class).to receive(:verify_received_account).and_return(true)
        allow_any_instance_of(AwardPolicy).to receive(:pay?).and_return(true)
        allow_any_instance_of(BlockchainJob::BlockchainTransactionSyncJob).to receive(:perform_later)
        allow_any_instance_of(described_class).to receive(:received_state).and_return({ 'transaction_id' => transaction.id, 'redirect_back_to' => '/dummy_redir_url' })
        allow_any_instance_of(BlockchainTransaction).to receive(:update).and_return(true)
        allow_any_instance_of(BlockchainTransaction).to receive(:update_status)
      end

      it 'updates received transaction, schedules a sync and returns 200' do
        get :receive, params: { transaction_id: 'dummy_tx_hash', signed_transaction: Base64.encode64('dummy_raw_tx') }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when callback includes error' do
      before do
        expect_any_instance_of(described_class).to receive(:verify_errorless).exactly(1).times.and_return(false)
        allow_any_instance_of(described_class).to receive(:received_state).and_return({ 'transaction_id' => transaction.id, 'redirect_back_to' => '/dummy_redir_url' })
      end

      it 'cancels received transaction and returns 200' do
        expect_any_instance_of(BlockchainTransaction).to receive(:update_status)

        get :receive, params: { transaction_id: 'dummy_tx_hash', signed_transaction: Base64.encode64('dummy_raw_tx') }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when callbacks account doesnt match current one' do
      before do
        expect_any_instance_of(described_class).to receive(:verify_errorless).exactly(1).times.and_return(true)
        expect_any_instance_of(described_class).to receive(:verify_received_account).and_return(false)
      end

      it 'returns 401' do
        get :receive, params: { transaction_id: 'dummy_tx_hash', signed_transaction: Base64.encode64('dummy_raw_tx') }
        expect(response).to have_http_status(401)
      end
    end
  end
end
