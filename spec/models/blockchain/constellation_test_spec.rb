require 'rails_helper'
require 'models/blockchain_spec'

describe Blockchain::ConstellationTest do
  it_behaves_like 'a blockchain'

  specify { expect(described_class.new.name).to eq('ConstellationTest') }
  specify { expect(described_class.new.explorer_api_host).to eq('dummy') }
  specify { expect(described_class.new.mainnet?).to be_falsey }
end
