require 'rails_helper'

describe Comakery::Eth::Tx, vcr: true do
  let(:eth_tx) { build(:eth_tx) }

  describe '#to_object' do
    subject { eth_tx.to_object }

    specify { expect(subject[:from]).to eq(eth_tx.blockchain_transaction.source) }
    specify { expect(subject[:to]).to eq(eth_tx.blockchain_transaction.destination) }
    specify { expect(subject[:value]).to eq(eth_tx.encode_value(eth_tx.blockchain_transaction.amount)) }
  end

  describe '#encode_value' do
    subject { eth_tx.encode_value(15) }

    it { is_expected.to eq('0xf') }
  end

  describe 'eth' do
    it 'returns Comakery::Eth' do
      expect(eth_tx.eth).to be_a(Comakery::Eth)
    end
  end

  describe 'hash' do
    it 'returns transaction hash' do
      expect(eth_tx.hash).to eq('0x5d372aec64aab2fc031b58a872fb6c5e11006c5eb703ef1dd38b4bcac2a9977d')
    end
  end

  describe 'data' do
    it 'returns transaction data' do
      expect(eth_tx.data).to be_a(Hash)
    end
  end

  describe 'receipt' do
    it 'returns transaction receipt' do
      expect(eth_tx.receipt).to be_a(Hash)
    end
  end

  describe 'block' do
    it 'returns transaction block' do
      expect(eth_tx.block).to be_a(Hash)
    end
  end

  describe 'block number' do
    it 'returns transaction block number' do
      expect(eth_tx.block_number).to eq(7121264)
    end
  end

  describe 'block time' do
    it 'returns transaction block time' do
      expect(eth_tx.block_time).to eq(Time.zone.at(1579027380))
    end
  end

  describe 'value' do
    it 'returns transaction value' do
      expect(eth_tx.value).to eq(0)
    end
  end

  describe 'from' do
    it 'returns transaction from' do
      expect(eth_tx.from).to eq('0x66ebd5cdf54743a6164b0138330f74dce436d842')
    end
  end

  describe 'to' do
    it 'returns transaction to' do
      expect(eth_tx.to).to eq('0x1d1592c28fff3d3e71b1d29e31147846026a0a37')
    end
  end

  describe 'input' do
    it 'returns transaction input' do
      expect(eth_tx.input).to eq('a9059cbb0000000000000000000000008599d17ac1cec71ca30264ddfaaca83c334f84510000000000000000000000000000000000000000000000000000000000000064')
    end
  end

  describe 'status' do
    it 'returns transaction status' do
      expect(eth_tx.status).to eq(1)
    end
  end

  describe 'confirmed?' do
    context 'for unconfirmed transaction' do
      let!(:eth_tx) { build(:eth_tx, hash: '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff') }

      it 'returns false' do
        expect(eth_tx.confirmed?).to be_falsey
      end
    end

    context 'for confirmed transaction with less than required confirmations' do
      let!(:eth_tx) { build(:eth_tx) }

      it 'returns false' do
        expect(eth_tx.confirmed?(5000000)).to be_falsey
      end
    end

    context 'for confirmed transaction' do
      let!(:eth_tx) { build(:eth_tx) }

      it 'returns true' do
        expect(eth_tx.confirmed?).to be_truthy
      end
    end
  end

  describe '#valid_block?' do
    subject { eth_tx.valid_block? }

    it { is_expected.to be_truthy }

    context 'for transaction block mined before tx current block' do
      before do
        allow_any_instance_of(described_class).to receive(:block_number).and_return(0)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_status?' do
    subject { eth_tx.valid_status? }

    it { is_expected.to be_truthy }

    context 'for transaction with failed status' do
      let!(:eth_tx) { build(:eth_tx, hash: '0x1bcda0a705a6d79935b77c8f05ab852102b1bc6aa90a508ac0c23a35d182289f') }

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_from?' do
    subject { eth_tx.valid_from? }

    it { is_expected.to be_truthy }

    context 'for transaction with incorrect source' do
      before do
        allow_any_instance_of(described_class).to receive(:from).and_return('0x0')
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_to?' do
    subject { eth_tx.valid_to? }

    it { is_expected.to be_truthy }

    context 'for transaction with incorrect destination' do
      before do
        allow_any_instance_of(described_class).to receive(:to).and_return('0x0')
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid_amount?' do
    subject { eth_tx.valid_amount? }

    it { is_expected.to be_truthy }

    context 'for transaction with incorrect amount' do
      before do
        allow_any_instance_of(described_class).to receive(:value).and_return(1)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#valid?' do
    subject { eth_tx.valid? }

    context 'for transaction block mined before tx current block' do
      before do
        allow_any_instance_of(described_class).to receive(:block_number).and_return(0)
      end

      it { is_expected.to be_falsey }
    end

    context 'for transaction with failed status' do
      let!(:eth_tx) { build(:eth_tx, hash: '0x1bcda0a705a6d79935b77c8f05ab852102b1bc6aa90a508ac0c23a35d182289f') }

      it { is_expected.to be_falsey }
    end

    context 'for transaction with incorrect source' do
      before do
        allow_any_instance_of(described_class).to receive(:from).and_return('0x0')
      end

      it { is_expected.to be_falsey }
    end

    context 'for transaction with incorrect destination' do
      before do
        allow_any_instance_of(described_class).to receive(:to).and_return('0x0')
      end

      it { is_expected.to be_falsey }
    end

    context 'for transaction with incorrect amount' do
      before do
        allow_any_instance_of(described_class).to receive(:value).and_return(1)
      end

      it { is_expected.to be_falsey }
    end

    context 'for correct transaction' do
      it { is_expected.to be_truthy }
    end
  end
end
