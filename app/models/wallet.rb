class Wallet < ApplicationRecord
  include BelongsToBlockchain
  include BelongsToOreId

  belongs_to :account
  belongs_to :project, optional: true
  has_many :balances, dependent: :destroy
  has_many :token_opt_ins, dependent: :destroy
  has_many :wallet_provisions, dependent: :destroy
  has_many :awards, foreign_key: :recipient_wallet_id, inverse_of: :recipient_wallet, dependent: :nullify
  has_many :account_token_records, dependent: :destroy
  has_many :projects, foreign_key: :hot_wallet_id, inverse_of: :hot_wallet, dependent: :nullify

  validates :source, presence: true
  validates :address, presence: true, unless: :pending?
  validates :address, blockchain_address: true
  validates :address, uniqueness: { scope: %i[account_id _blockchain], message: 'has already been taken for the blockchain' }
  validates :_blockchain, uniqueness: { scope: %i[account_id primary_wallet], message: 'has primary wallet already' }, if: :primary_wallet?
  validates :name, presence: true

  validate :validate_project_id

  attr_readonly :_blockchain

  before_create :set_primary_flag
  after_commit :mark_first_wallet_as_primary, on: [:destroy], if: :primary_wallet?

  enum source: { user_provided: 0, ore_id: 1, hot_wallet: 2 }

  def available_blockchains
    available_blockchains = Blockchain.available
    available_blockchains.reject!(&:supported_by_ore_id?)
    available_blockchains.map(&:key)
  end

  def validate_project_id
    errors.add(:project_id, 'can be assigned only for hot wallet') if project.present? && !hot_wallet?
  end

  def pending?
    ore_id? && ore_id_account&.pending?
  end

  def coin_balance
    balance = balances.find_or_create_by(token: coin_of_the_blockchain)
    balance.update(base_unit_value: blockchain.account_coin_balance(address))
    balance
  end

  def set_primary_flag
    self.primary_wallet = !Wallet.exists?(account_id: account_id,
                                          _blockchain: _blockchain,
                                          primary_wallet: true)
  end

  def mark_first_wallet_as_primary
    first_wallet_in_network = Wallet
                              .where(account_id: account_id, _blockchain: _blockchain)
                              .order(id: :asc)
                              .first

    first_wallet_in_network&.update_column(:primary_wallet, true) # rubocop:disable Rails/SkipsModelValidations
  end
end
