class TransferRule < ApplicationRecord
  include BlockchainTransactable

  belongs_to :token
  belongs_to :sending_group, class_name: 'RegGroup', foreign_key: 'sending_group_id'
  belongs_to :receiving_group, class_name: 'RegGroup', foreign_key: 'receiving_group_id'

  after_initialize :set_defaults
  after_save :replace_existing_rule, if: -> { synced? }

  LOCKUP_UNTIL_MAX = Time.zone.at(2.pow(256) - 1)
  LOCKUP_UNTIL_MIN = Time.zone.at(0)

  attr_readonly :token_id, :sending_group_id, :receiving_group_id, :lockup_until
  validates_with ComakeryTokenValidator
  validates :lockup_until, inclusion: { in: LOCKUP_UNTIL_MIN..LOCKUP_UNTIL_MAX }
  validate :groups_belong_to_same_token

  enum status: %i[created pending synced failed]

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
      if sending_group&.token != token
        errors.add(:sending_group, "should belong to #{token.name} token")
      end

      if receiving_group&.token != token
        errors.add(:receiving_group, "should belong to #{token.name} token")
      end
    end

    def replace_existing_rule
      TransferRule.where(sending_group: sending_group, receiving_group: receiving_group, status: :synced).where.not(id: id).destroy_all
    end
end
