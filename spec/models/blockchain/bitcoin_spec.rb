require 'rails_helper'
require 'models/blockchain_spec'

describe Blockchain::Bitcoin do
  it_behaves_like 'a blockchain'

  specify { expect(described_class.new.name).to eq('Bitcoin') }
  specify { expect(described_class.new.explorer_api_host).to eq('example.org') }
  specify { expect(described_class.new.explorer_human_host).to eq('live.blockcypher.com/btc') }
  specify { expect(described_class.new.mainnet?).to be_truthy }
  specify { expect(described_class.new.number_of_confirmations).to eq(1) }
  specify { expect(described_class.new.sync_period).to eq(60) }
  specify { expect(described_class.new.sync_max).to eq(10) }
  specify { expect(described_class.new.sync_waiting).to eq(600) }
  specify { expect(described_class.new.url_for_tx_human('null')).to eq('https://live.blockcypher.com/btc/tx/null') }
  specify { expect(described_class.new.url_for_tx_api('null')).to eq('https://example.org/tx/null') }
  specify { expect(described_class.new.url_for_address_human('null')).to eq('https://live.blockcypher.com/btc/address/null') }
  specify { expect(described_class.new.url_for_address_api('null')).to eq('https://example.org/addr/null') }
end
