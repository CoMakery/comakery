class TransferRule < ApplicationRecord
  belongs_to :token
  belongs_to :sending_group, class_name: 'RegGroup', foreign_key: 'sending_group_id'
  belongs_to :receiving_group, class_name: 'RegGroup', foreign_key: 'receiving_group_id'

  after_initialize :set_defaults

  validates_with ComakeryTokenValidator
  validates :sending_group, uniqueness: { scope: %i[receiving_group] }
  validates :receiving_group, uniqueness: { scope: %i[sending_group] }

  validate :groups_belong_to_same_token

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
end
