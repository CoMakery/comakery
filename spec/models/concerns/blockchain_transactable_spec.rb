shared_examples 'blockchain_transactable' do
  it { is_expected.to have_many(:blockchain_transactions) }
  it { is_expected.to have_one(:latest_blockchain_transaction) }

  describe 'latest_blockchain_transaction' do
    it 'returns record which belong to correct type and id' do
      transaction = create(:blockchain_transaction_transfer_rule)
      account_token_record = create(:account_token_record, id: transaction.blockchain_transactable.id)

      expect(transaction.blockchain_transactable.latest_blockchain_transaction).to eq(transaction)
      expect(account_token_record.latest_blockchain_transaction).to be_nil
    end
  end

  describe 'blockchain_transaction_class' do
    subject { described_class.new.blockchain_transaction_class }

    it { is_expected.to eq("BlockchainTransaction#{described_class}".constantize) }
  end

  describe 'new_blockchain_transaction' do
    subject { described_class.new.new_blockchain_transaction({}) }

    it { is_expected.to be_a("BlockchainTransaction#{described_class}".constantize) }
  end
end
