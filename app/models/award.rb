class Award < ApplicationRecord
  paginates_per 50

  include EthereumAddressable

  belongs_to :account
  belongs_to :award_type
  has_one :project, through: :award_type

  validates :proof_id, :account, :award_type, :unit_amount, :total_amount, :quantity, presence: true
  validates :quantity, :total_amount, :unit_amount, numericality: { greater_than: 0 }

  validates :ethereum_transaction_address, ethereum_address: { type: :transaction, immutable: true } # see EthereumAddressable

  before_validation :ensure_proof_id_exists

  def self.total_awarded
    sum(:total_amount)
  end

  def ensure_proof_id_exists
    self.proof_id ||= SecureRandom.base58(44) # 58^44 > 2^256
  end

  def ethereum_issue_ready?
    project.ethereum_enabled &&
      recipient_address.present? &&
      ethereum_transaction_address.blank?
  end

  def self_issued?
    account_id == project.account_id
  end

  def recipient_display_name
    account.name
  end

  def recipient_slack_user_name
    account.name
  end

  def recipient_address
    account.ethereum_wallet
  end

  def issuer_display_name
    project.account.name
  end

  def issuer_slack_user_name
    project.account.name
  end

  # TODO: update after refactor award/channels
  def team_image
    project.teams.first&.image
  end

  def total_amount=(x)
    self[:total_amount] = x.round
  end

  private

  def slack_team_id
    project.slack_team_id
  end
end
