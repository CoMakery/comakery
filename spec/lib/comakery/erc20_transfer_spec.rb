require 'rails_helper'

describe Comakery::Erc20Transfer, vcr: true do
  describe 'valid_method_id?' do
    context 'for erc20 transfer transaction' do
      let!(:erc20_transfer) { build(:erc20_transfer) }

      it 'returns true' do
        expect(erc20_transfer.valid_method_id?).to be_truthy
      end
    end

    context 'for other erc20 transactions' do
      let!(:erc20_transfer) { build(:erc20_transfer, hash: '0x1007e9116efab368169683b81ae576bd48e168bef2be1fea5ef096ccc9e5dcc0') }

      it 'returns false' do
        expect(erc20_transfer.valid_method_id?).to be_falsey
      end
    end
  end

  describe 'method_arg_1' do
    let!(:erc20_transfer) { build(:erc20_transfer) }

    it 'returns destination' do
      expect(erc20_transfer.method_arg_1).to eq('0x8599d17ac1cec71ca30264ddfaaca83c334f8451')
    end
  end

  describe 'method_arg_2' do
    let!(:erc20_transfer) { build(:erc20_transfer) }

    it 'returns amount' do
      expect(erc20_transfer.method_arg_2).to eq(100)
    end
  end

  describe 'valid?' do
    context 'for invalid eth transaction' do
      let!(:erc20_transfer) { build(:erc20_transfer) }

      it 'returns false' do
        expect(erc20_transfer.valid?('0x66ebd5cdf54743a6164b0138330f74dce436d842', '0x1d1592c28fff3d3e71b1d29e31147846026a0a37', '0x8599d17ac1cec71ca30264ddfaaca83c334f8451', 100, Time.current)).to be_falsey
      end
    end

    context 'for erc20 non-transfer transaction' do
      let!(:erc20_transfer) { build(:erc20_transfer, hash: '0x1007e9116efab368169683b81ae576bd48e168bef2be1fea5ef096ccc9e5dcc0') }

      it 'returns false' do
        expect(erc20_transfer.valid?('0x75f538eafdb14a2dc9f3909aa1e0ea19727ff44b', '0x1d1592c28fff3d3e71b1d29e31147846026a0a37', '0x75f538eafdb14a2dc9f3909aa1e0ea19727ff44b', 5, Time.zone.at(0))).to be_falsey
      end
    end

    context 'for erc20 transfer with incorrect destination' do
      let!(:erc20_transfer) { build(:erc20_transfer) }

      it 'returns false' do
        expect(erc20_transfer.valid?('0x66ebd5cdf54743a6164b0138330f74dce436d842', '0x1d1592c28fff3d3e71b1d29e31147846026a0a37', '0x66ebd5cdf54743a6164b0138330f74dce436d842', 100, Time.zone.at(0))).to be_falsey
      end
    end

    context 'for erc20 transfer with incorrect amount' do
      let!(:erc20_transfer) { build(:erc20_transfer) }

      it 'returns false' do
        expect(erc20_transfer.valid?('0x66ebd5cdf54743a6164b0138330f74dce436d842', '0x1d1592c28fff3d3e71b1d29e31147846026a0a37', '0x8599d17ac1cec71ca30264ddfaaca83c334f8451', 1, Time.zone.at(0))).to be_falsey
      end
    end

    context 'for correct erc20 transfer' do
      let!(:erc20_transfer) { build(:erc20_transfer) }

      it 'returns true' do
        expect(erc20_transfer.valid?('0x66ebd5cdf54743a6164b0138330f74dce436d842', '0x1d1592c28fff3d3e71b1d29e31147846026a0a37', '0x8599d17ac1cec71ca30264ddfaaca83c334f8451', 100, Time.zone.at(0))).to be_truthy
      end
    end
  end
end
