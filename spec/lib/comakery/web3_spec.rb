require 'rails_helper'

describe Comakery::Web3 do
  describe 'fetch_symbol_and_decimals' do
    it 'returns correct symbol and decimals' do
      web3 = described_class.new 'main'
      stub_web3_fetch
      symbol, decimals = web3.fetch_symbol_and_decimals '0x6c6ee5e31d828de241282b9606c8e98ea48526e2'
      expect(symbol).to eq 'HOT'
      expect(decimals).not_to eq nil

      web3 = described_class.new 'test'
      stub_web3_fetch('test.infura.io')
      symbol, decimals = web3.fetch_symbol_and_decimals '0x6c6ee5e31d828de241282b9606c8e98ea48526e2'
      expect(symbol).to eq 'HOT'
      expect(decimals).not_to eq nil

      web3 = described_class.new 'main'
      stub_web3_fetch_failure
      symbol, decimals = web3.fetch_symbol_and_decimals '0x6c6ee5e31d828de241282b9606c8e98ea48526e2'
      expect(symbol).to eq nil
      expect(decimals).to eq nil
    end
  end
end
