require 'rails_helper'
require 'models/token_type_spec'

describe TokenType::AlgorandSecurityToken, vcr: true do
  it_behaves_like 'a token type'

  let(:attrs) { { contract_address: '13997710', blockchain: Blockchain::AlgorandTest.new } }

  specify { expect(described_class.new(**attrs).name).to eq('ALGORAND_SECURITY_TOKEN') }
  specify { expect(described_class.new(**attrs).symbol).to eq('ABCTEST') }
  specify { expect(described_class.new(**attrs).decimals).to eq(8) }
  specify { expect(described_class.new(**attrs).wallet_logo).to eq('OREID_Logo_Symbol.svg') }
  specify { expect(described_class.new(**attrs).abi).to eq({}) }
  specify { expect(described_class.new(**attrs).tx).to be_nil }
  specify { expect(described_class.new(**attrs).operates_with_smart_contracts?).to be_truthy }
  specify { expect(described_class.new(**attrs).operates_with_account_records?).to be_truthy }
  specify { expect(described_class.new(**attrs).operates_with_reg_groups?).to be_truthy }
  specify { expect(described_class.new(**attrs).operates_with_transfer_rules?).to be_truthy }
  specify { expect(described_class.new(**attrs).supports_token_mint?).to be_truthy }
  specify { expect(described_class.new(**attrs).supports_token_burn?).to be_truthy }
  specify { expect(described_class.new(**attrs).supports_token_freeze?).to be_truthy }
  specify { expect(described_class.new(**attrs).default_reg_group).to eq(1) }
  specify { expect(described_class.new(**attrs).transfer_rule_sync_job).to eq(AlgorandSecurityToken::TransferRulesSyncJob) }
  specify { expect(described_class.new(**attrs).accounts_sync_job).to eq(AlgorandSecurityToken::AccountTokenRecordsSyncJob) }

  describe 'contract' do
    context 'when contract_address is invalid' do
      let(:attrs) { { contract_address: 'DUMMY', blockchain: Blockchain::AlgorandTest.new } }

      it 'raises an error' do
        expect { described_class.new(**attrs).contract }.to raise_error(TokenType::Contract::ValidationError)
      end
    end

    context 'when contract_address doesnt exist on network' do
      let(:attrs) { { contract_address: '0', blockchain: Blockchain::AlgorandTest.new } }

      it 'raises an error' do
        expect { described_class.new(**attrs).contract }.to raise_error(TokenType::Contract::ValidationError)
      end
    end
  end

  describe '#blockchain_balance' do
    let(:token_type) { described_class.new(**attrs) }
    subject { token_type.blockchain_balance('dummy_wallet_address') }

    it 'gets balance from a contract' do
      expect_any_instance_of(Comakery::Algorand).to receive(:app_balance).with('dummy_wallet_address').and_return(999)

      is_expected.to eq 999
    end
  end
end
