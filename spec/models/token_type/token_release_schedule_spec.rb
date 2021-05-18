require 'rails_helper'
require 'models/token_type_spec'

describe TokenType::TokenReleaseSchedule, vcr: true do
  it_behaves_like 'a token type'

  let(:attrs) { { contract_address: '0x9608848FA0063063d2Bb401e8B5efFcb8152Ec65', blockchain: Blockchain::EthereumRinkeby.new } }

  specify { expect(described_class.new(**attrs).name).to eq('Token Release Schedule') }
  specify { expect(described_class.new(**attrs).symbol).to eq('XYZ Lockup') }
  specify { expect(described_class.new(**attrs).decimals).to eq(10) }
  specify { expect(described_class.new(**attrs).wallet_logo).to eq('wallet-connect-logo.svg') }
  specify { expect(described_class.new(**attrs).contract).to be_a(Comakery::Eth::Contract::Erc20) }
  specify { expect(described_class.new(**attrs).abi).to be_an(Array) }
  specify { expect(described_class.new(**attrs).tx).to be_nil }
  specify { expect(described_class.new(**attrs).operates_with_smart_contracts?).to be_truthy }
  specify { expect(described_class.new(**attrs).operates_with_account_records?).to be_falsey }
  specify { expect(described_class.new(**attrs).operates_with_reg_groups?).to be_falsey }
  specify { expect(described_class.new(**attrs).operates_with_transfer_rules?).to be_falsey }
  specify { expect(described_class.new(**attrs).supports_token_mint?).to be_falsey }
  specify { expect(described_class.new(**attrs).supports_token_burn?).to be_falsey }
  specify { expect(described_class.new(**attrs).supports_token_freeze?).to be_falsey }
  specify { expect(described_class.new(**attrs).supports_balance?).to be_truthy }

  describe '#contract' do
    context 'when contract_address is invalid' do
      let(:attrs) { { contract_address: '0x', blockchain: Blockchain::EthereumRopsten.new } }

      it 'raises an error' do
        expect { described_class.new(**attrs).contract }.to raise_error(TokenType::Contract::ValidationError)
      end
    end

    context 'when contract_address doesnt exist on network' do
      let(:attrs) { { contract_address: '0x583cbbb8a8443b38abcc0c956bece47340ea1368', blockchain: Blockchain::EthereumRopsten.new } }

      it 'raises an error' do
        expect { described_class.new(**attrs).contract }.to raise_error(TokenType::Contract::ValidationError)
      end
    end
  end

  describe '#blockchain_balance' do
    let(:token_type) { described_class.new(**attrs) }
    subject { token_type.blockchain_balance('0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1') }

    it { is_expected.to eq 800000000000 }
  end

  describe '#blockchain_locked_balance' do
    let(:token_type) { described_class.new(**attrs) }
    subject { token_type.blockchain_locked_balance('0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1') }

    it { is_expected.to eq 100000000000 }
  end

  describe '#blockchain_unlocked_balance' do
    let(:token_type) { described_class.new(**attrs) }
    subject { token_type.blockchain_unlocked_balance('0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1') }

    it { is_expected.to eq 700000000000 }
  end
end
