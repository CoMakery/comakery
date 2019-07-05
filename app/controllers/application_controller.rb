require 'application_responder'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html
  # layout 'raw'
  include Pundit
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # require account logins for all pages by default
  # (public pages use skip_before_action :require_login)
  before_action :require_login, :require_email_confirmation, :check_age, :require_build_profile
  before_action :basic_auth

  def basic_auth
    return unless ENV.key?('BASIC_AUTH')

    basic_auth_name, basic_auth_password = ENV.fetch('BASIC_AUTH').split(':')

    return true unless basic_auth_name.present? && basic_auth_password.present?

    site_name = I18n.t('project_name')
    authenticate_or_request_with_http_basic(site_name) do |name, password|
      compare_all([name, basic_auth_name], [password, basic_auth_password])
    end
  end

  # called from before_filter :require_login
  def not_authenticated(msg = nil)
    respond_to do |format|
      format.html { redirect_to new_account_url, alert: msg }
      format.json { head :unauthorized }
    end
  rescue ActionController::UnknownFormat
    head :unauthorized
  end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def not_found(e)
    if Rails.env.development?
      raise e
    else
      redirect_to '/404.html'
    end
  end

  rescue_from Slack::Web::Api::Error do |exception|
    Rails.logger.error(exception.to_s)
    flash[:error] = 'Error talking to Slack, sorry!'
    session.delete(:account_id)
    redirect_to root_url
  end

  # called when a policy authorization fails
  rescue_from Pundit::NotAuthorizedError do |exception|
    Rails.logger.error(exception.to_s)
    redirect_to root_path
  end

  def require_login
    not_authenticated if session[:account_id].blank?
  end

  def require_email_confirmation
    if current_account && !current_account&.confirmed? && !current_account&.valid_and_underage?
      redirect_to root_path, flash: { warning: 'Please confirm your email address to continue' }
    end
  end

  def require_build_profile
    if current_account && (current_account.name_required = true) && !current_account.valid?
      @account = current_account
      @skip_validation = true
      flash[:error] = "Please complete your profile info for #{current_account.errors.keys.join(', ').humanize.titleize}"
      render 'accounts/build_profile', layout: 'application'
    end
  end

  def redirect_if_signed_in
    return redirect_to root_path if current_account
  end

  def check_age
    if current_account && current_account.valid_and_underage? && controller_name != 'accounts'
      redirect_to build_profile_accounts_path, alert: 'Sorry, you must be 18 years or older to use this website'
    end
  end

  def current_account
    @current_account ||= Account.find_by(id: session[:account_id])
  end

  def error
    @error ||= nil
  end

  def notice
    @notice ||= nil
  end

  helper_method :current_account, :error, :notice
  alias current_user current_account
  helper_method :current_user

  def assign_project
    @project = Project.find_by(id: params[:project_id] || params[:id])&.decorate
  end

  def task_to_props(task)
    task&.serializable_hash&.merge({
      description_html: Comakery::Markdown.to_html(task.description),
      requirements_html: Comakery::Markdown.to_html(task.requirements),
      specialty: task.specialty&.name,
      mission: {
        name: task.project&.mission&.name,
        url: task.project&.mission ? mission_path(task.project&.mission) : nil
      },
      token: {
        currency: task.project&.token&.symbol,
        logo: helpers.attachment_url(task.project&.token, :logo_image, :fill, 100, 100)
      },
      project: {
        id: task.project&.id,
        name: task.project&.title,
        url: task.project && (task.project.unlisted? ? unlisted_project_path(task.project.long_id) : project_path(task.project)),
        channels: task.project.channels.map do |channel|
          {
            type: channel.provider,
            name: channel.name,
            url: channel.url,
            id: channel.id
          }
        end
      },
      issuer: {
        name: task.issuer&.decorate&.name,
        image: helpers.account_image_url(task.issuer, 100),
        self: task.issuer == current_account
      },
      contributor: {
        name: task.account&.decorate&.name,
        image: helpers.account_image_url(task.account, 100),
        wallet_present: task.account&.decorate&.can_receive_awards?(task.project)
      },
      allowedToStart: true,
      experience_level_name: Award::EXPERIENCE_LEVELS.key(task.experience_level),
      image_url: helpers.attachment_url(task, :image),
      submission_image_url: helpers.attachment_url(task, :submission_image),
      payment_url: awards_project_path(task.project),
      details_url: project_award_type_award_path(task.project, task.award_type, task),
      start_url: project_award_type_award_start_path(task.project, task.award_type, task),
      submit_url: project_award_type_award_submit_path(task.project, task.award_type, task),
      accept_url: project_award_type_award_accept_path(task.project, task.award_type, task),
      reject_url: project_award_type_award_reject_path(task.project, task.award_type, task),
      updated_at: helpers.time_ago_in_words(task.updated_at)
    })
  end

  # :nocov:

  def d(the_proc)
    return if Rails.env.test?
    unless the_proc.instance_of?(Proc)
      return STDERR.puts("d expected an instance of Proc, got #{the_proc.try(:inspect)}")
    end
    source = the_proc.try(:source).try(:match, /\s*proc { (.+) }\s*/).try(:[], 1)
    logger.debug "#{source} ===>>> " if source
    value = the_proc.call
    begin
      value = JSON.pretty_generate value, indent: '    '
      logger.debug "\n#{value}"
    rescue JSON::GeneratorError
      logger.debug value
    end
  end

  private

  def compare_all(*pairs)
    pairs.map do |a, b|
      ActiveSupport::SecurityUtils.variable_size_secure_compare(a, b)
    end.reduce(:&)
  end
end
