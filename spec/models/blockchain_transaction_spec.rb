require 'rails_helper'

describe BlockchainTransaction, vcr: true do
  describe 'associations' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }
    let!(:blockchain_transaction_update) { create(:blockchain_transaction_update, blockchain_transaction: blockchain_transaction) }

    it 'belongs to blockchain_transactable' do
      expect(blockchain_transaction.blockchain_transactable).to be_an(Award)
    end

    it 'has_one token' do
      expect(blockchain_transaction.token).to be_a(Token)
    end

    it 'has_many updates' do
      expect(blockchain_transaction.updates.last).to eq(blockchain_transaction_update)
    end
  end

  describe 'validations' do
    it 'makes attributes readonly' do
      %i[amount source destination network contract_address current_block].each do |attr|
        expect(described_class.readonly_attributes).to include(attr.to_s)
      end
    end
  end

  describe 'callbacks' do
    let!(:blockchain_transaction) { create(:blockchain_transaction, nonce: 0) }
    let!(:blockchain_transaction_dag) { create(:blockchain_transaction, token: create(:dag_token)) }

    context 'with an ethereum coin type' do
      it 'populates contract address and network from token' do
        expect(blockchain_transaction.network).to eq(blockchain_transaction.token._blockchain)
        expect(blockchain_transaction.contract_address).to eq(blockchain_transaction.token.contract_address)
      end

      it 'sets current block' do
        expect(blockchain_transaction.current_block).to eq(8697793)
      end
    end

    context 'with a dag token' do
      it 'populates network from token' do
        expect(blockchain_transaction_dag.network).to eq(blockchain_transaction_dag.token._blockchain)
      end
    end
  end

  describe 'update_status' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }

    before do
      blockchain_transaction.update_status(:pending, 'test')
    end

    it 'updates status and status message attributes' do
      expect(blockchain_transaction.status).to eq('pending')
      expect(blockchain_transaction.status_message).to eq('test')
    end

    it 'creates new blockchain_transaction_update' do
      expect(blockchain_transaction.updates.last.status).to eq('pending')
      expect(blockchain_transaction.updates.last.status_message).to eq('test')
    end
  end

  describe 'sync', :vcr do
    let!(:succeed_blockchain_transaction) do
      create(
        :blockchain_transaction,
        tx_hash: '0x5d372aec64aab2fc031b58a872fb6c5e11006c5eb703ef1dd38b4bcac2a9977d',
        source: '0x66ebd5cdf54743a6164b0138330f74dce436d842',
        destination: '0x8599d17ac1cec71ca30264ddfaaca83c334f8451',
        amount: 100,
        current_block: 0
      )
    end

    let!(:failed_blockchain_transaction) { create(:blockchain_transaction, nonce: 1, tx_hash: '0x94f00ce58c31913178e1aeab790967f7f62545126de118a064249a883c4159d4', current_block: 0) }
    let!(:unconfirmed_blockchain_transaction) { create(:blockchain_transaction, nonce: 1, tx_hash: '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', current_block: 0) }

    it 'udpates status to succeed for successfull transaction' do
      succeed_blockchain_transaction.sync

      expect(succeed_blockchain_transaction.reload.status).to eq('succeed')
    end

    it 'udpates status to failed for failed transaction' do
      failed_blockchain_transaction.sync

      expect(failed_blockchain_transaction.reload.status).to eq('failed')
      expect(failed_blockchain_transaction.reload.status_message).to eq('Failed on chain')
    end

    it 'returns false for unconfirmed transaction' do
      expect(unconfirmed_blockchain_transaction.sync).to be_falsey
    end

    it 'calls update_number_of_syncs' do
      succeed_blockchain_transaction.sync

      expect(succeed_blockchain_transaction.reload.number_of_syncs).to eq(1)
    end
  end

  describe 'number_of_confirmations' do
    it 'gets value from ENV' do
      ENV['BLOCKCHAIN_TX__NUMBER_OF_CONFIRMATIONS'] = '1'
      expect(described_class.number_of_confirmations).to eq(1)
      ENV['BLOCKCHAIN_TX__NUMBER_OF_CONFIRMATIONS'] = nil
    end

    it 'has default value' do
      expect(described_class.number_of_confirmations).to eq(3)
    end
  end

  describe 'seconds_to_wait_between_syncs' do
    it 'gets value from ENV' do
      ENV['BLOCKCHAIN_TX__SECONDS_TO_WAIT_BETWEEN_SYNCS'] = '1'
      expect(described_class.seconds_to_wait_between_syncs).to eq(1)
      ENV['BLOCKCHAIN_TX__SECONDS_TO_WAIT_BETWEEN_SYNCS'] = nil
    end

    it 'has default value' do
      expect(described_class.seconds_to_wait_between_syncs).to eq(10)
    end
  end

  describe 'seconds_to_wait_in_created' do
    it 'gets value from ENV' do
      ENV['BLOCKCHAIN_TX__SECONDS_TO_WAIT_IN_CREATED'] = '1'
      expect(described_class.seconds_to_wait_in_created).to eq(1)
      ENV['BLOCKCHAIN_TX__SECONDS_TO_WAIT_IN_CREATED'] = nil
    end

    it 'has default value' do
      expect(described_class.seconds_to_wait_in_created).to eq(600)
    end
  end

  describe 'max_syncs' do
    it 'gets value from ENV' do
      ENV['BLOCKCHAIN_TX__MAX_SYNCS'] = '1'
      expect(described_class.max_syncs).to eq(1)
      ENV['BLOCKCHAIN_TX__MAX_SYNCS'] = nil
    end

    it 'has default value' do
      expect(described_class.max_syncs).to eq(60)
    end
  end

  describe 'reached_max_syncs?' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }

    it 'returns true if number_of_syncs is equal or greater than max_syncs' do
      blockchain_transaction.update(number_of_syncs: described_class.max_syncs)
      blockchain_transaction.reload

      expect(blockchain_transaction.reached_max_syncs?).to be_truthy
    end

    it 'returns false if number_of_syncs is less than max_syncs' do
      blockchain_transaction.update(number_of_syncs: described_class.max_syncs - 1)
      blockchain_transaction.reload

      expect(blockchain_transaction.reached_max_syncs?).to be_falsey
    end
  end

  describe 'waiting_in_created?' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }

    it 'returns true if created_at less than seconds_to_wait_in_created ago' do
      blockchain_transaction.update(created_at: 1.year.from_now)
      blockchain_transaction.reload

      expect(blockchain_transaction.waiting_in_created?).to be_truthy
    end

    it 'returns false if created_at greater than seconds_to_wait_in_created ago' do
      blockchain_transaction.update(created_at: 1.year.ago)
      blockchain_transaction.reload

      expect(blockchain_transaction.waiting_in_created?).to be_falsey
    end

    it 'returns false if not in created state' do
      blockchain_transaction.update(status: :failed)
      blockchain_transaction.reload

      expect(blockchain_transaction.waiting_in_created?).to be_falsey
    end
  end

  describe 'waiting_till_next_sync_is_allowed?' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }

    it 'returns true if synced_at less than seconds_to_wait_between_syncs ago' do
      blockchain_transaction.update(synced_at: 1.year.from_now + described_class.seconds_to_wait_between_syncs)
      blockchain_transaction.reload

      expect(blockchain_transaction.waiting_till_next_sync_is_allowed?).to be_truthy
    end

    it 'returns false if synced_at greater than seconds_to_wait_between_syncs ago' do
      blockchain_transaction.update(synced_at: 1.year.ago - described_class.seconds_to_wait_between_syncs)
      blockchain_transaction.reload

      expect(blockchain_transaction.waiting_till_next_sync_is_allowed?).to be_falsey
    end
  end

  describe 'update_number_of_syncs' do
    let!(:blockchain_transaction) { create(:blockchain_transaction) }

    it 'increments number_of_syncs and updates synced_at' do
      blockchain_transaction.update_number_of_syncs
      blockchain_transaction.reload

      expect(blockchain_transaction.number_of_syncs).to eq(1)
      expect(blockchain_transaction.synced_at).not_to be_nil
    end

    it 'updates status to cancelled if max_syncs is reached' do
      blockchain_transaction.update(status: :pending, number_of_syncs: described_class.max_syncs - 1)
      blockchain_transaction.update_number_of_syncs
      blockchain_transaction.reload

      expect(blockchain_transaction.status).to eq('cancelled')
    end
  end

  describe 'contract' do
    let!(:blockchain_transaction) { create(:blockchain_transaction, nonce: 0) }
    let!(:blockchain_transaction_dag) { create(:blockchain_transaction, token: create(:dag_token)) }

    context 'with an ethereum coin type' do
      it 'returns a contract instance' do
        expect(blockchain_transaction.contract).to be_a(Comakery::Eth::Contract::Erc20)
      end
    end

    context 'with an unsupported coin type' do
      it 'raises error' do
        expect { blockchain_transaction_dag.contract }.to raise_error(/Contract parsing is not implemented/)
      end
    end
  end

  describe '.migrate_awards_to_blockchain_transactable' do
    context 'when transaction belongs to an award' do
      let!(:blockchain_transaction) do
        create(
          :blockchain_transaction,
          award_id: create(
            :blockchain_transaction__award,
            token: create(:blockchain_transaction).token
          ).id
        )
      end

      it 'copies award_id to blockchain_transactable_id and populates blockchain_transactable_type' do
        described_class.migrate_awards_to_blockchain_transactable
        expect(blockchain_transaction.reload.blockchain_transactable_id).to eq(blockchain_transaction.award_id)
        expect(blockchain_transaction.reload.blockchain_transactable_type).to eq('Award')
      end
    end

    context 'when transaction doesnt belong to an award' do
      let!(:blockchain_transaction) { create(:blockchain_transaction) }

      it 'does nothing' do
        described_class.migrate_awards_to_blockchain_transactable
        expect(blockchain_transaction.reload.blockchain_transactable_id).not_to eq(blockchain_transaction.award_id)
      end
    end
  end
end
