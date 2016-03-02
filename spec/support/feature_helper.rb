module FeatureHelper
  def xstep(title, &block)
    puts "PENDING STEP SKIPPED: #{title}" unless ENV["QUIET_TESTS"]
  end

  def step(title, &block)
    puts "STEP: #{title}" unless ENV["QUIET_TESTS"]
    block.call
  end

  def wut
    save_and_open_page
  end

  def login(account)
    page.set_rack_session(:account_id => account.id)
  end

end
