class TransferRule < ApplicationRecord
  include BlockchainTransactable
  include Refreshable

  belongs_to :token
  belongs_to :sending_group, class_name: 'RegGroup'
  belongs_to :receiving_group, class_name: 'RegGroup'

  after_initialize :set_defaults
  after_save :replace_existing_rule, if: -> { synced? }
  after_save :destroy_self_if_lockup_zero, if: -> { synced? }

  LOCKUP_UNTIL_MAX = Time.zone.at(2.pow(256) - 1)
  LOCKUP_UNTIL_MIN = Time.zone.at(0)

  attr_readonly :token_id, :sending_group_id, :receiving_group_id, :lockup_until
  validates_with SecurityTokenValidator
  validates :lockup_until, inclusion: { in: LOCKUP_UNTIL_MIN..LOCKUP_UNTIL_MAX }
  validate :groups_belong_to_same_token

  enum status: { created: 0, pending: 1, synced: 2, failed: 3, outdated: 4 }
  scope :not_synced, -> { where.not(status: :synced) }

  def lockup_until
    super && Time.zone.at(super)
  end

  def lockup_until=(time)
    super(time.to_i.to_d)
  end

  private

    def set_defaults
      self.lockup_until ||= Time.current
    end

    def groups_belong_to_same_token
      errors.add(:sending_group, "should belong to #{token.name} token") if sending_group&.token != token

      errors.add(:receiving_group, "should belong to #{token.name} token") if receiving_group&.token != token
    end

    def replace_existing_rule
      TransferRule
        .where(sending_group: sending_group, receiving_group: receiving_group, status: :synced)
        .where.not(id: id)
        .outdate_all
    end

    def destroy_self_if_lockup_zero
      destroy if lockup_until.to_i.zero?
    end
end
