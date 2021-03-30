module Api::V1::Concerns::RequiresRecoverySignature
  extend ActiveSupport::Concern
  include Api::V1::Concerns::RequiresSignature

  included do
    def api_public_key
      whitelabel_mission&.wallet_recovery_api_public_key
    end
  end
end
