class AccountTokenRecord < ApplicationRecord
  include BlockchainTransactable
  include Refreshable

  belongs_to :account
  belongs_to :token
  belongs_to :reg_group
  belongs_to :wallet

  after_initialize :set_defaults
  before_validation :set_wallet
  before_save :touch_account
  after_save :replace_existing_record, if: -> { synced? }

  LOCKUP_UNTIL_MAX = Time.zone.at(2.pow(256) - 1)
  LOCKUP_UNTIL_MIN = Time.zone.at(0)
  BALANCE_MAX = 2.pow(256) - 1
  BALANCE_MIN = 0

  attr_readonly :account_id, :token_id, :reg_group_id, :max_balance, :account_frozen, :lockup_until, :balance
  validates_with SecurityTokenValidator
  validates :lockup_until, inclusion: { in: LOCKUP_UNTIL_MIN..LOCKUP_UNTIL_MAX }
  validates :max_balance, inclusion: { in: BALANCE_MIN..BALANCE_MAX }

  enum status: { created: 0, pending: 1, synced: 2, failed: 3, outdated: 4 }

  delegate :_blockchain, :blockchain, to: :token

  def lockup_until
    super && Time.zone.at(super)
  end

  def lockup_until=(time)
    super(time.to_i.to_d)
  end

  def balance
    balance = Balance.find_or_create_by(wallet_id: wallet_id, token_id: token_id)
    SyncBalanceJob.set(queue: :critical).perform_later(balance)
    balance
  end

  private

    def set_defaults
      self.lockup_until ||= 0
      self.reg_group ||= RegGroup.default_for(token)
    end

    def set_wallet
      self.wallet ||= account.wallets.find_by(_blockchain: token._blockchain, primary_wallet: true)
    end

    def touch_account
      account&.touch # rubocop:disable Rails/SkipsModelValidations
    end

    def replace_existing_record
      AccountTokenRecord
        .where(account_id: account_id, token_id: token_id, status: :synced)
        .where.not(id: id)
        .outdate_all
    end
end
