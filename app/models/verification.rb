class Verification < ApplicationRecord
  belongs_to :account
  belongs_to :provider, class_name: 'Account'

  validates :passed, inclusion: { in: [true, false], message: 'is not boolean' }
  validates :max_investment_usd, numericality: { greater_than: 0 }

  after_update_commit :broadcast_update, if: :saved_change_to_passed?

  after_create :set_account_latest_verification

  enum verification_type: { "aml-kyc": 0, accreditation: 1, "valid-identity": 2 }

  def failed?
    !passed?
  end

  private

    def broadcast_update
      account.wallets.each do |wallet|
        broadcast_replace_to "mission_#{account.managed_mission&.id}_account_wallets",
                             target: "account_#{account.id}_wallet_#{wallet.id}",
                             partial: 'accounts/partials/index/wallet',
                             locals: { wallet: wallet.decorate }
      end
    end

    def set_account_latest_verification
      account.update(latest_verification: self)
    end
end
