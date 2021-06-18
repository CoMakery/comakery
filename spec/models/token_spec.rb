require 'rails_helper'
require 'models/concerns/belongs_to_blockchain_spec'
require 'models/concerns/blockchain_transactable_spec'

describe Token, type: :model, vcr: true do
  it_behaves_like 'belongs_to_blockchain'
  it_behaves_like 'blockchain_transactable'
  it_behaves_like 'active_storage_validator', ['logo_image']

  it { is_expected.to have_many(:projects) }
  it { is_expected.to have_many(:accounts) }
  it { is_expected.to have_many(:account_token_records) }
  it { is_expected.to have_many(:reg_groups) }
  it { is_expected.to have_many(:transfer_rules) }
  it { is_expected.to have_many(:blockchain_transactions) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to validate_presence_of(:_token_type) }
  it { is_expected.to validate_presence_of(:denomination) }
  it { is_expected.to define_enum_for(:_token_type) }

  describe described_class.new do
    it { is_expected.to respond_to(:contract) }
    it { is_expected.to respond_to(:abi) }
    it { is_expected.to respond_to(:batch_abi) }
    it { is_expected.to respond_to(:supports_balance?) }
    it { is_expected.to respond_to(:blockchain_balance) }
    it { is_expected.to respond_to(:blockchain_locked_balance) }
    it { is_expected.to respond_to(:blockchain_unlocked_balance) }
  end

  describe described_class.support_balance do
    let!(:token_with_balance_support) { create(:token, _token_type: :eth, _blockchain: :ethereum_ropsten) }
    let!(:token_without_balance_support) { create(:token, _token_type: :btc) }

    it { is_expected.to include(token_with_balance_support) }
    it { is_expected.not_to include(token_without_balance_support) }
  end

  describe 'scopes' do
    describe '.listed' do
      let!(:token) { create(:token) }
      let!(:token_unlisted)  { create(:token, unlisted: true) }

      it 'returns all tokens expect unlisted ones' do
        expect(described_class.listed).to include(token)
        expect(described_class.listed).not_to include(token_unlisted)
      end
    end
  end

  describe 'denomination' do
    it 'should contain the platform wide currencies' do
      expect(described_class.denominations.map { |x, _| x }.sort).to eq(Comakery::Currency::DENOMINATIONS.keys.sort)
    end
  end

  describe 'set_values_from_token_type' do
    it 'loads values from token_type before validation' do
      token = Token.create!(_token_type: :btc, _blockchain: :bitcoin)

      expect(token.name).to eq("#{token.token_type&.name&.upcase} (#{token.blockchain&.name})")
      expect(token.symbol).to eq(token.token_type.symbol)
      expect(token.decimal_places).to eq(token.token_type.decimals)
    end

    context 'when custom values are provided' do
      it 'keeps the values' do
        attrs = {
          name: 'Dummy Coin',
          symbol: 'DMC',
          decimal_places: 2
        }

        token = Token.create!(_token_type: :btc, _blockchain: :bitcoin, **attrs)

        expect(token.name).to eq(attrs[:name])
        expect(token.symbol).to eq(attrs[:symbol])
        expect(token.decimal_places).to eq(attrs[:decimal_places])
      end
    end

    context 'when provided contract address is incorrect' do
      it 'adds an error' do
        expect(described_class.new(_token_type: :erc20, _blockchain: :ethereum_ropsten, contract_address: '1').valid?).to be_falsey
      end
    end
  end

  describe 'token' do
    subject { described_class.new }
    specify { expect(subject.token).to eq(subject) }
  end

  describe 'token_type' do
    it 'returns a TokenType instance' do
      expect(described_class.new.token_type).to be_a(TokenType::Btc)
    end
  end

  describe 'abi' do
    let!(:comakery_token) { create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten) }
    let!(:token) { create(:token, _token_type: 'erc20', _blockchain: :ethereum_ropsten, contract_address: build(:ethereum_contract_address)) }

    it 'returns correct abi for Comakery Token' do
      expect(comakery_token.abi.last['name']).to eq('transfer')
    end

    it 'returns default abi for other tokens' do
      expect(token.abi.last['name']).to eq('Transfer')
    end
  end

  describe 'to_base_unit' do
    it 'converts an amount from BigDecimal into a Integer base unit based on token decimals' do
      expect(create(:token, decimal_places: 18).to_base_unit(BigDecimal(1) + 0.1)).to eq(1100000000000000000)
      expect(create(:token, decimal_places: 2).to_base_unit(BigDecimal(1) + 0.1)).to eq(110)
      expect(create(:token, decimal_places: 0).to_base_unit(BigDecimal(1) + 0.1)).to eq(1)
    end
  end

  describe 'from_base_unit' do
    it 'converts an amount from base unit into a BigDecimal based on token decimals' do
      expect(create(:token, decimal_places: 18).from_base_unit(1100000000000000000)).to eq(BigDecimal(1) + 0.1)
      expect(create(:token, decimal_places: 2).from_base_unit(110)).to eq(BigDecimal(1) + 0.1)
      expect(create(:token, decimal_places: 0).from_base_unit(1)).to eq(BigDecimal(1))
    end
  end

  describe 'default_reg_group' do
    it 'returns default reg group for token' do
      expect(create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten).default_reg_group).to be_a(RegGroup)
    end
  end

  describe '#supports_batch_transfers?' do
    let(:token) { create(:token) }
    subject { token.supports_batch_transfers? }

    it { is_expected.to be_falsey }

    context 'with a lockup token' do
      let(:token) { create(:lockup_token) }
      it { is_expected.to be_truthy }
    end

    context 'with erc20 token' do
      let(:token) { create(:erc20_token) }

      it { is_expected.to be_falsey }

      context 'and batch contract address present' do
        let(:token) { create(:erc20_token, batch_contract_address: '0x0') }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#blockchain_transaction_class' do
    subject(:blockchain_transaction_class) { token.blockchain_transaction_class }

    context 'when token is frozen' do
      let(:token) { build :token, token_frozen: true }

      it 'should return correct class' do
        expect(blockchain_transaction_class).to eq BlockchainTransactionTokenUnfreeze
      end
    end

    context 'when token is not frozen' do
      let(:token) { build :token, token_frozen: false }

      it 'should return correct class' do
        expect(blockchain_transaction_class).to eq BlockchainTransactionTokenFreeze
      end
    end
  end

  describe '#_token_type_on_qtum?' do
    subject(:result) { token._token_type_on_qtum? }

    (Blockchain.list.keys - %i[qtum qtum_test]).each do |blockchain|
      context "when blockchain is #{blockchain}" do
        let(:token) { build :token, _blockchain: blockchain }

        it 'should return false' do
          expect(result).to eq false
        end
      end
    end

    %i[qtum qtum_test].each do |blockchain|
      context "when blockchain is #{blockchain}" do
        let(:token) { build :token, _blockchain: blockchain }

        it 'should return true' do
          expect(result).to eq true
        end
      end
    end
  end
end
