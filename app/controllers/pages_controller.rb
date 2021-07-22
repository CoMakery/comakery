class PagesController < ApplicationController
  before_action :unavailable_for_whitelabel

  skip_before_action :require_login
  skip_before_action :require_email_confirmation
  skip_after_action :verify_authorized

  layout 'legacy', except: [:styleguide]

  def contribution_licenses
    case params[:type]
    when 'CP'
      type = 'CP'
    when 'RP'
      type = 'RP'
    else
      return redirect_to('/404.html')
    end

    path = Rails.root.join('lib', 'assets', 'contribution_licenses', "#{type}-*.md")
    license = Dir.glob(path).max_by { |f| File.mtime(f) }
    @license_md = File.read(license)
  end

  def styleguide
    redirect_to :root unless Rails.env.development?
  end
end
