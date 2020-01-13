class Verification < ApplicationRecord
  belongs_to :account
  belongs_to :provider, class_name: 'Account', foreign_key: 'provider_id'

  validates :passed, inclusion: { in: [true, false], message: 'is not boolean' }
  validates :max_investment_usd, numericality: { greater_than: 0 }

  after_create :set_account_latest_verification

  enum verification_type: %i[aml-kyc accreditation valid-identity]

  def failed?
    !passed?
  end

  private

    def set_account_latest_verification
      account.update(latest_verification: self)
    end
end
