class OreIdWalletBalanceSyncJob < ApplicationJob
  queue_as :default

  def perform(wallet_provision)
    return unless wallet_provision

    unless wallet_provision.sync_allowed?
      reschedule(wallet_provision)
      return
    end

    sync = wallet_provision.create_synchronisation

    begin
      wallet_provision.sync_balance
    rescue StandardError => e
      sync.failed!
      reschedule(wallet_provision)
      Sentry.capture_exception(e)
    else
      sync.ok!
    end
  end

  def reschedule(wallet_provision)
    self.class.set(wait: wait_to_perform(wallet_provision)).perform_later(wallet_provision)
  end

  def wait_to_perform(wallet_provision)
    if wallet_provision.next_sync_allowed_after < Time.current
      0
    else
      wallet_provision.next_sync_allowed_after - Time.current
    end
  end
end
