class Token < ApplicationRecord
  include BelongsToBlockchain
  include BlockchainTransactable
  include PrepareImage

  nilify_blanks

  has_one_attached_and_prepare_image :logo_image

  has_many :projects # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :accounts, through: :projects, source: :accounts
  has_many :account_token_records # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :reg_groups # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :transfer_rules # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :blockchain_transactions # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :token_opt_ins, dependent: :destroy

  validates :name, uniqueness: true # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :name, :symbol, :decimal_places, :_token_type, :denomination, presence: true

  before_validation :set_values_from_token_type
  after_create :default_reg_group, if: -> { token_type.operates_with_reg_groups? }

  scope :listed, -> { where unlisted: false }
  scope :available_for_algorand_opt_in, -> { where(_token_type: %w[asa algorand_security_token]) }
  scope :available_for_provision, -> { where(_token_type: %w[asa algorand_security_token]) }
  scope :support_balance, -> { where(_token_type: TokenType.with_balance_support_list) }

  enum denomination: {
    USD: 0,
    BTC: 1,
    ETH: 2
  }
  enum coin_type: {
    erc20: 'ERC20',
    eth: 'ETH',
    qrc20: 'QRC20',
    qtum: 'QTUM',
    ada: 'ADA',
    btc: 'BTC',
    eos: 'EOS',
    xtz: 'XTZ',
    comakery: 'Comakery Security Token',
    dag: 'DAG'
  }, _prefix: :coin_type # Deprecated
  enum ethereum_network: {
    main: 'Main Ethereum Network',
    ropsten: 'Ropsten Test Network',
    kovan: 'Kovan Test Network',
    rinkeby: 'Rinkeby Test Network'
  }, _prefix: :deprecated # Deprecated
  enum blockchain_network: {
    bitcoin_mainnet: 'Main Bitcoin Network',
    bitcoin_testnet: 'Test Bitcoin Network',
    cardano_mainnet: 'Main Cardano Network',
    cardano_testnet: 'Test Cardano Network',
    qtum_mainnet: 'Main QTUM Network',
    qtum_testnet: 'Test QTUM Network',
    eos_mainnet: 'Main EOS Network',
    eos_testnet: 'Test EOS Network',
    tezos_mainnet: 'Main Tezos Network',
    constellation_mainnet: 'Main Constellation Network',
    constellation_testnet: 'Test Constellation Network',
    main: 'Main Ethereum Network',
    ropsten: 'Ropsten Test Network',
    kovan: 'Kovan Test Network',
    rinkeby: 'Rinkeby Test Network'
  } # Deprecated

  enum _token_type: TokenType.list, _prefix: :_token_type

  delegate(
    :contract,
    :abi,
    :batch_abi,
    :supports_balance?,
    :blockchain_balance,
    :blockchain_locked_balance,
    :blockchain_unlocked_balance,
    to: :token_type
  )

  ransacker :network, formatter: proc { |v| Blockchain.list[v.to_sym] } do |parent|
    parent.table[:_blockchain]
  end

  def token
    self
  end

  def blockchain_transaction_class
    if token_frozen?
      'BlockchainTransactionTokenUnfreeze'
    else
      'BlockchainTransactionTokenFreeze'
    end.constantize
  end

  def token_type
    if _token_type
      @token_type ||= "TokenType::#{_token_type.camelize}".constantize.new(
        blockchain: blockchain,
        contract_address: contract_address
      )
    end
  end

  def _token_type_token?
    token_type&.operates_with_smart_contracts?
  end

  def _token_type_on_ethereum?
    blockchain&.name&.match?(/^Ethereum/)
  end

  def _token_type_on_algorand?
    blockchain&.name&.match?(/^Algorand/)
  end

  def _token_type_on_qtum?
    blockchain&.name&.match?(/^Qtum/)
  end

  def to_base_unit(amount)
    BigDecimal(10.pow(decimal_places || 0) * amount)&.to_s&.to_i
  end

  def from_base_unit(amount)
    BigDecimal(amount).div(BigDecimal(10.pow(decimal_places || 0)), decimal_places || 0)
  end

  def default_reg_group
    RegGroup.default_for(self)
  end

  def supports_batch_transfers?
    _token_type_token_release_schedule? \
    || (_token_type_erc20? && batch_contract_address.present?)
  end

  private

    def set_values_from_token_type # rubocop:todo Metrics/CyclomaticComplexity
      self.name ||= "#{token_type&.name&.upcase} (#{blockchain&.name})"
      self.symbol ||= token_type&.symbol
      self.decimal_places ||= token_type&.decimals || 0

      self.ethereum_enabled ||= (token_type&.operates_with_smart_contracts? && _token_type_on_ethereum?) # Deprecated
    rescue TokenType::Contract::ValidationError => e
      errors.add(:contract_address, e.message)
    end
end
