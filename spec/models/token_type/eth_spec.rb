require 'rails_helper'
require 'models/token_type_spec'

describe TokenType::Eth do
  it_behaves_like 'a token type'

  specify { expect(described_class.new.name).to eq('ETH') }
  specify { expect(described_class.new.symbol).to eq('ETH') }
  specify { expect(described_class.new.decimals).to eq(18) }
  specify { expect(described_class.new.wallet_logo).to eq('metamask2.png') }
  specify { expect(described_class.new.contract).to be_nil }
  specify { expect(described_class.new.abi).to eq({}) }
  specify { expect(described_class.new.tx).to eq(Comakery::Eth::Tx) }
  specify { expect(described_class.new.operates_with_smart_contracts?).to be_falsey }
  specify { expect(described_class.new.operates_with_account_records?).to be_falsey }
  specify { expect(described_class.new.operates_with_reg_groups?).to be_falsey }
  specify { expect(described_class.new.operates_with_transfer_rules?).to be_falsey }
  specify { expect(described_class.new.supports_token_mint?).to be_falsey }
  specify { expect(described_class.new.supports_token_burn?).to be_falsey }
  specify { expect(described_class.new.supports_token_freeze?).to be_falsey }
end
