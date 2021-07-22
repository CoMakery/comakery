module Refreshable
  extend ActiveSupport::Concern

  # Requires `:synced` scope and `:synced_at` timestamp

  included do
    def self.fresh?
      last_sync = synced.order(synced_at: :desc).first&.synced_at
      last_sync && last_sync > 10.minutes.ago
    end

    def self.outdate_all
      update_all(status: :outdated) # rubocop:todo Rails/SkipsModelValidations
    end
  end
end
