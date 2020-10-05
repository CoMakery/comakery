class Wallet < ApplicationRecord
  include BelongsToBlockchain

  belongs_to :account
  has_many :balances, dependent: :destroy

  validates :address, :state, :source, presence: true
  validates :address, blockchain_address: true
  validates :_blockchain, uniqueness: { scope: :account_id, message: 'has already wallet added' }

  attr_readonly :_blockchain

  enum state: { ok: 0, unclaimed: 1, pending: 2 }
  enum source: { user_provided: 0, ore_id: 1 }

  before_create :pending_for_ore_id

  def available_blockchains
    Wallet._blockchains.keys - account.wallets.pluck(:_blockchain)
  end

  private

    def pending_for_ore_id
      self.state = :pending if ore_id?
    end
end
