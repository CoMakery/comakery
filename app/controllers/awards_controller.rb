class AwardsController < ApplicationController
  before_action :set_project, except: %i[index confirm]
  before_action :unavailable_for_whitelabel, only: %i[index]
  before_action :authorize_project_edit, except: %i[index show confirm start submit accept reject assign destroy]
  before_action :set_award_type, except: %i[index confirm]
  before_action :set_award, except: %i[index new create confirm]
  before_action :authorize_award_create, only: %i[create new]
  before_action :authorize_award_show, only: %i[show]
  before_action :authorize_award_edit, only: %i[edit update send_award]
  before_action :authorize_award_assign, only: %i[assign]
  before_action :authorize_award_start, only: %i[start]
  before_action :authorize_award_submit, only: %i[submit]
  before_action :authorize_award_review, only: %i[accept reject]
  before_action :authorize_award_pay, only: %i[update_transaction_address]
  before_action :clone_award_on_start, only: %i[start]
  before_action :set_filter, only: %i[index]
  before_action :set_default_project_filter, only: %i[index]
  before_action :set_project_filter, only: %i[index]
  before_action :run_award_expiration, only: %i[index]
  before_action :set_awards, only: %i[index]
  before_action :set_page, only: %i[index]
  before_action :set_form_props, only: %i[new edit clone]
  before_action :set_show_props, only: %i[show]
  before_action :set_award_props, only: %i[award]
  before_action :set_assignment_props, only: %i[assignment]
  before_action :set_index_props, only: %i[index]
  skip_before_action :verify_authenticity_token, only: %i[update_transaction_address]
  skip_before_action :require_login, only: %i[confirm show]
  skip_after_action :verify_authorized, only: %i[confirm]
  skip_after_action :verify_policy_scoped, only: %(index)
  before_action :redirect_back_to_session, only: %i[index]
  before_action :create_project_role_from_session, only: %i[index]

  def index; end

  def new; end

  def award; end

  def assignment; end

  def clone
    @props[:task][:image_from_id] = @award.id
  end

  def show
    @skip_search_box = true
  end

  def edit
    @props[:form_url] = project_award_type_award_path(@project, @award_type, @award)
    @props[:form_action] = 'PATCH'
  end

  def create
    result = CreateAward.call(
      award_type: @award_type,
      award_params: award_params,
      account: current_account,
      image_from_id: params[:task][:image_from_id]
    )

    @award = result.award

    if result.success?
      set_ok_response
      render json: @ok_response, status: :ok
    else
      error_response
      render json: @error_response, status: :unprocessable_entity
    end
  end

  def update
    image_validator = ImagePixelValidator.new(@award, award_params)

    if image_validator.valid? && @award.update(award_params) && @award.update(issuer: current_account)
      set_ok_response
      render json: @ok_response, status: :ok
    else
      error_response
      render json: @error_response, status: :unprocessable_entity
    end
  end

  def assign # rubocop:todo Metrics/CyclomaticComplexity
    account = Account.find(params[:account_id])

    @award = @award.clone_on_assignment if @award.should_be_cloned? && @award.can_be_cloned_for?(account)

    if account && @award.update(account: account, issuer: current_account, status: 'ready')
      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_assigned.deliver_now
      redirect_to project_award_types_path(@award.project), notice: 'Task has been assigned'
    else
      redirect_to project_award_types_path(@award.project), flash: { error: @award.errors&.full_messages&.join(', ') }
    end
  end

  def start
    if @award.update(account: current_account, status: 'started')
      redirect_to project_award_type_award_path(@project, @award_type, @award), notice: 'Task started'
    else
      redirect_to my_tasks_path(filter: 'ready'), flash: { error: @award.errors&.full_messages&.join(', ') }
    end
  end

  def submit # rubocop:todo Metrics/CyclomaticComplexity
    if submit_params[:submission_url].blank? &&
       submit_params[:submission_comment].blank? &&
       submit_params[:submission_image].blank?

      redirect_to project_award_type_award_path(@project, @award_type, @award), flash: { error: 'You must submit a comment, image or URL documenting your work.' }
    elsif @award.update(submit_params.merge(status: 'submitted'))
      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_submitted.deliver_now
      redirect_to my_tasks_path(filter: 'submitted'), notice: 'Task submitted'
    else
      redirect_to project_award_type_award_path(@project, @award_type, @award), flash: { error: @award.errors&.full_messages&.join(', ') }
    end
  end

  def accept
    if @award.update(status: 'accepted')
      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_accepted.deliver_now
      redirect_to my_tasks_path(filter: 'to pay'), notice: 'Task accepted'
    else
      redirect_to my_tasks_path(filter: 'to review'), flash: { error: @award.errors&.full_messages&.join(', ') }
    end
  end

  def reject
    if @award.update(status: 'rejected')
      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_rejected.deliver_now
      redirect_to my_tasks_path(filter: 'done'), notice: 'Task rejected'
    else
      redirect_to my_tasks_path(filter: 'to review'), flash: { error: @award.errors&.full_messages&.join(', ') }
    end
  end

  def destroy
    authorize @award, :cancel?

    if @award.update(status: 'cancelled')
      redirect_back(fallback_location: project_award_types_path, notice: 'Task cancelled')
    else
      redirect_back(fallback_location: project_award_types_path, flash: { error: @award.errors&.full_messages&.join(', ') })
    end
  end

  def recipient_address
    @project.token ? set_recipient_address_response : set_recipient_address_response_for_missing_token
    render json: @recipient_address_response, status: :ok
  end

  def send_award
    result = SendAward.call(
      award: @award,
      quantity: send_award_params[:quantity],
      message: send_award_params[:message],
      channel_id: send_award_params[:channel_id],
      uid: send_award_params[:uid],
      email: send_award_params[:email]
    )

    if result.success?
      @award = result.award

      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_accepted_direct.deliver_now
      @award.send_award_notifications

      if @award.account&.decorate&.can_receive_awards?(@project)
        session[:last_award_id] = @award.id
        @award.account&.update new_award_notice: true
      end
      flash[:notice] = send_award_notice
      head :ok
    else
      error_response(result.message)
      render json: @error_response, status: :unprocessable_entity
    end
  end

  def update_transaction_address
    if params[:tx]
      @award.handle_tx_hash(params[:tx], current_account)
      TaskMailer.with(award: @award, whitelabel_mission: @whitelabel_mission).task_paid.deliver_now
    elsif params[:receipt]
      @award.handle_tx_receipt(params[:receipt])
    elsif params[:error]
      @award.handle_tx_error(params[:error])
    end

    @award = @award.decorate
    render layout: false
  end

  def confirm
    if current_account
      award = Award.find_by confirm_token: params[:token]
      if award
        flash[:notice] = confirm_message(award.project) if award.confirm!(current_account)
        redirect_to project_path(award.project)
      else
        flash[:error] = 'Invalid award token!'
        redirect_to root_path
      end
    else
      session[:redeem] = true
      flash[:notice] = "Please #{view_context.link_to 'log in', new_session_path} or #{view_context.link_to 'signup', new_account_path} before receiving your award"
      redirect_to new_account_path
    end
  end

  private

    def set_project
      @project = @project_scope.find_by(id: params[:project_id])&.decorate
      redirect_to('/404.html') unless @project
    end

    def authorize_project_edit
      authorize @project, :edit?
    end

    def authorize_award_create
      authorize (@award || @award_type.awards.new), :create?
    end

    def authorize_award_show
      authorize @award, :show?
    end

    def authorize_award_edit
      authorize @award, :edit?
    end

    def authorize_award_assign
      authorize @award, :assign?
    end

    def authorize_award_start
      if policy(@award).start?
        authorize @award, :start?
      else
        redirect_to my_tasks_path, notice: unlock_award_notice
      end
    end

    def unlock_award_notice
      if @award.specialty == Specialty.default
        "Complete #{current_account.tasks_to_unlock(@award)} more tasks to access General tasks that require the #{Award::EXPERIENCE_LEVELS.key(@award.experience_level)} skill level"
      else
        "Complete #{current_account.tasks_to_unlock(@award)} more #{@award.specialty.name} tasks to access tasks that require the #{Award::EXPERIENCE_LEVELS.key(@award.experience_level)} skill level"
      end
    end

    def authorize_award_submit
      authorize @award, :submit?
    end

    def authorize_award_review
      authorize @award, :review?
    end

    def authorize_award_pay
      authorize @award, :pay?
    end

    def clone_award_on_start
      @award = @award.clone_on_assignment if @award.should_be_cloned? && @award.can_be_cloned_for?(current_account)
    end

    def set_award_type
      @award_type = @project.award_types.find(params[:award_type_id])
    end

    def set_award
      @award = Award.find(params[:id] || params[:award_id])
    end

    def set_filter
      @filter = params[:filter]&.downcase || 'ready'
    end

    def set_default_project_filter
      default_project_id = ENV['DEFAULT_PROJECT_ID']

      @project = @project_scope.find_by(id: default_project_id) if @filter == 'ready' && !params[:all] && current_account.experiences.empty? && default_project_id.present?
    end

    def set_project_filter
      @project = (@project_scope.find_by(id: params[:project_id]) || @project)
    end

    def run_award_expiration
      current_account.accessable_awards(projects_involved).includes(:issuer, :account, :award_type, :cloned_from, project: [:account, :mission, :token, :admins, channels: [:team]]).started.where(expires_at: Time.zone.at(0)..Time.current).each(&:run_expiration)
    end

    def projects_involved
      current_user.whitelabel_involved_projects(@whitelabel_mission)
    end

    def set_awards
      @awards =
        current_account
        .accessable_awards(projects_involved)
        .includes(
          :specialty, :issuer, :award_type, :cloned_from,
          project: [:account, :mission, :token, :project_admins, channels: [:team]],
          account: [image_attachment: :blob]
        ).filtered_for_view(@filter, current_account)
        .order(expires_at: :asc, updated_at: :desc)
        .with_all_attached_images

      @awards = @awards.where(award_type: AwardType.where(project: @project)) if @project
    end

    def set_page
      @page = (params[:page] || 1).to_i
      @awards_paginated = @awards.page(@page).per(20)
      redirect_to '/404.html' if (@page > 1) && @awards_paginated.out_of_range?
    end

    def award_params
      params.fetch(:task, {}).permit(
        :name,
        :why,
        :description,
        :image,
        :requirements,
        :experience_level,
        :amount,
        :number_of_assignments,
        :number_of_assignments_per_user,
        :specialty_id,
        :transfer_type_id,
        :proof_link,
        :expires_in_days
      )
    end

    def send_award_params
      params.fetch(:task, {}).permit(
        :quantity,
        :message,
        :channel_id,
        :uid,
        :email
      )
    end

    def submit_params
      params.fetch(:task, {}).permit(
        :submission_url,
        :submission_comment,
        :submission_image
      )
    end

    def set_index_props
      @props = {
        tasks: @awards_paginated.map { |task| task_to_props(task) },
        pagination_html: helpers.paginate(@awards_paginated, window: 3),
        filters: ['ready', 'started', 'submitted', 'to review', 'to pay', 'done'].map do |filter|
          {
            name: filter,
            current: filter == @filter,
            count: current_account.accessable_awards(projects_involved).filtered_for_view(filter, current_account).size,
            url: my_tasks_path(filter: filter)
          }
        end,
        project: @project,
        past_awards_url: show_account_path
      }
    end

    def set_show_props
      @props = if current_account
        {
          task: task_to_props(@award),
          task_allowed_to_start: policy(@award).start?,
          task_reached_maximum_assignments: @award.reached_maximum_assignments_for?(current_account),
          tasks_to_unlock: current_account.tasks_to_unlock(@award),
          license_url: contribution_licenses_path(type: 'CP'),
          my_tasks_path: my_tasks_path,
          account_name: current_account.decorate.name,
          csrf_token: form_authenticity_token
        }
      else
        {
          task: task_to_props(@award),
          task_allowed_to_start: false,
          task_reached_maximum_assignments: @award.reached_maximum_assignments_for?(current_account),
          tasks_to_unlock: nil,
          license_url: contribution_licenses_path(type: 'CP'),
          my_tasks_path: my_tasks_path,
          account_name: nil,
          csrf_token: form_authenticity_token
        }
      end
    end

    def account_accessible_channels
      @project.channels.includes(:team).select { |c| c.team.accounts.include?(current_account) }
    end

    def set_award_props # rubocop:todo Metrics/CyclomaticComplexity
      @props = {
        task: @award.serializable_hash,
        batch: @award_type.serializable_hash,
        project: @project.serializable_hash,
        token: @project.token ? @project.token.serializable_hash : {},
        channels: (account_accessible_channels + [Channel.new(name: 'Email')]).map { |c| [c.name || c.channel_id, c.id.to_s] }.to_h,
        members: account_accessible_channels.map { |c| [c.id.to_s, c.members.to_h] }.to_h,
        recipient_address_url: project_award_type_award_recipient_address_path(@project, @award_type, @award),
        form_url: project_award_type_award_send_award_path(@project, @award_type, @award),
        form_action: 'POST',
        url_on_success: project_award_types_path,
        csrf_token: form_authenticity_token,
        project_for_header: @@project.header_props(current_account),
        mission_for_header: @whitelabel_mission ? nil : @project&.mission&.decorate&.header_props
      }
    end

    def set_assignment_props # rubocop:todo Metrics/CyclomaticComplexity
      @props = {
        task: @award.serializable_hash(only: %w[id name]),
        batch: @award_type.serializable_hash(only: %w[id name]),
        project: @project.serializable_hash(only: %w[id title], methods: :public?)&.merge({
          url: unlisted_project_url(@project.long_id)
        }),
        accounts: (@project.accounts + @project.contributors).uniq.map do |a|
          a.decorate.serializable_hash(
            only: %i[id nickname first_name last_name linkedin_url github_url dribble_url behance_url],
            methods: :image_url
          )
        end,
        accounts_select: (@project.accounts + @project.contributors).uniq.map { |a| [a.decorate.name, a.id] }.unshift(['', nil]).to_h,
        form_url: project_award_type_award_assign_path(@project, @award_type, @award),
        csrf_token: form_authenticity_token,
        project_for_header: @@project.header_props(current_account),
        mission_for_header: @whitelabel_mission ? nil : @project&.mission&.decorate&.header_props
      }
    end

    def set_form_props # rubocop:todo Metrics/CyclomaticComplexity
      award_image_path = GetImageVariantPath.call(
        attachment: (@award || @award_type.awards.new).image,
        resize_to_fill: [300, 300]
      ).path
      @props = {
        task: (@award || @award_type.awards.new).serializable_hash&.merge(
          image_url: award_image_path
        ),
        batch: @award_type.serializable_hash,
        project: @project.serializable_hash,
        token: @project.token ? @project.token.serializable_hash : {},
        experience_levels: Award::EXPERIENCE_LEVELS,
        specialties: Specialty.all.map { |s| [s.name, s.id] }.unshift(['General', nil]).to_h,
        types: @project.transfer_types.reject { |t| t.name.in? %w[mint burn] }.collect { |t| [t.name.titlecase, t.id] }.to_h,
        form_url: project_award_type_awards_path(@project, @award_type),
        form_action: 'POST',
        url_on_success: project_award_types_path,
        csrf_token: form_authenticity_token,
        project_for_header: @@project.header_props(current_account),
        mission_for_header: @whitelabel_mission ? nil : @project&.mission&.decorate&.header_props
      }
    end

    def set_ok_response
      @ok_response = {
        id: @award.id,
        message: (action_name == 'create' ? 'Task created' : 'Task updated'),
        form_url: project_award_type_award_path(@project, @award_type, @award),
        edit_url: edit_project_award_type_award_path(@project, @award_type, @award)
      }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def error_response(message = nil) # rubocop:todo Metrics/CyclomaticComplexity
      @error_response = {
        id: @award.id,
        message: message || @award.errors&.full_messages&.join(', '),
        errors: @award.errors&.messages&.map { |k, v| ["task[#{k}]", v.to_sentence] }.to_h
      }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def set_recipient_address_response # rubocop:todo Metrics/CyclomaticComplexity
      address = (
        if params[:channel_id].blank?
          Account.where('lower(email)=?', params[:email].downcase).first
        else
          Account.find_from_uid_channel(params[:uid], Channel.find_by(id: params[:channel_id]))
        end
      )&.address_for_blockchain(@project.token&._blockchain)

      wallet_url = address ? @project.token&.blockchain&.url_for_address_human(address) : nil

      @recipient_address_response = {
        address: address,
        wallet_url: wallet_url
      }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def set_recipient_address_response_for_missing_token
      @recipient_address_response = {
        address: nil,
        wallet_url: nil
      }.deep_transform_keys { |key| key.to_s.camelize(:lower) }
    end

    def send_award_notice
      if !@award.self_issued? && @award.decorate.recipient_address.blank?
        "The award recipient hasn't entered a blockchain address for us to send the award to. When the recipient enters their blockchain address you will be able to approve the token transfer on the awards page."
      else
        "#{@award.decorate.recipient_display_name.possessive} task has been accepted. Initiate payment for the task on the payments page."
      end
    end

    def confirm_message(project)
      return nil unless project.token

      blockchain_name = project.token.blockchain.name
      addr = current_account.address_for_blockchain(project.token._blockchain)

      if addr.present?
        "Congratulations, you just claimed your award! Your #{blockchain_name} address is #{addr}. You can change the address on your #{view_context.link_to('wallets page', wallets_path)}. The project owner can now issue the tokens."
      else
        "Congratulations, you just claimed your award! Be sure to enter your #{blockchain_name} adress on your #{view_context.link_to('wallets page', wallets_path)} to receive your tokens."
      end
    end
end
