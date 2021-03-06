require 'rails_helper'

RSpec.describe BlockchainJob::ComakerySecurityTokenJob::AccountSyncJob, type: :job do
  let(:token) { stub_blockchain_sync && create(:token, _token_type: :comakery_security_token, symbol: 'TEST', decimal_places: 0, contract_address: '0x0000000000000000000000000000000000000000', _blockchain: 'ethereum') }
  let(:wallet) { create(:wallet, address: '0x0000000000000000000000000000000000000000', _blockchain: token._blockchain) }
  let(:record) { create(:account_token_record, account: wallet.account, token: token, wallet: wallet) }

  it 'updates account_token_record' do
    described_class.perform_now(record)
    expect(record.reload.synced_at).not_to be_nil
    expect(record.status).to eq 'synced'
  end

  context 'when account doesnt have a wallet' do
    let!(:record) { create(:account_token_record, token: token) }

    before do
      record.update_columns(wallet_id: nil) # rubocop:todo Rails/SkipsModelValidations
      record.account.wallets.delete_all
    end

    it 'does nothing' do
      described_class.perform_now(record)
      expect(record.reload.synced_at).to be_nil
      expect(record.status).to eq 'created'
    end
  end
end
