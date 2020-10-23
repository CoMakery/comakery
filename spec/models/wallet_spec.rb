require 'rails_helper'
require 'models/concerns/belongs_to_blockchain_spec'

describe Wallet, type: :model do
  it_behaves_like 'belongs_to_blockchain', { blockchain_addressable_columns: [:address] }

  subject { build(:wallet) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to belong_to(:ore_id).optional }
  it { is_expected.to have_many(:balances).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_uniqueness_of(:_blockchain).scoped_to(:account_id).with_message('has already wallet added').ignoring_case_sensitivity }
  it { is_expected.to have_readonly_attribute(:_blockchain) }
  it { is_expected.to define_enum_for(:state).with_values({ ok: 0, unclaimed: 1, pending: 2 }) }
  it { is_expected.to define_enum_for(:source).with_values({ user_provided: 0, ore_id: 1 }) }
  it { is_expected.not_to validate_presence_of(:ore_id_id) }
  it { expect(subject.state).to eq('ok') }
  it { expect(subject.ore_id).to be_nil }
  it { expect(subject.ore_id_password_reset_url('localhost')).to be_nil }

  context 'when ore_id?' do
    subject { create(:wallet, source: :ore_id) }

    it { is_expected.to validate_presence_of(:ore_id_id) }
    it { expect(subject.state).to eq('ok') }
    it { expect(subject.ore_id).to be_an(OreId) }
    it { expect(subject.ore_id_password_reset_url('localhost')).to eq('https://example.org?redirect=localhost') }

    context 'and address is missing' do
      subject { build(:wallet, source: :ore_id) }
      before { subject.address = nil }
      it { expect(subject.state).to eq('pending') }
    end

    context 'and pending?' do
      subject { build(:wallet, state: :pending, source: :ore_id) }
      it { is_expected.not_to validate_presence_of(:address) }
    end

    context 'and ok?' do
      subject { build(:wallet, state: :ok, source: :ore_id) }
      it { is_expected.not_to validate_presence_of(:address) }
    end
  end

  describe '#available_blockchains' do
    subject { create(:wallet) }

    it 'returns list of avaiable blockchains for creating a new wallet with the same account' do
      expect(subject.available_blockchains).not_to include(subject._blockchain)
    end
  end
end
