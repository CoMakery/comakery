class AwardsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[update_transaction_address preview]

  before_action :assign_project, only: %i[create index update_transaction_address]
  skip_before_action :require_login, only: %i[index confirm]
  skip_after_action :verify_authorized

  def index
    authorize @project, :show_contributions?
    @awards = @project.awards
    @awards = @awards.where(account_id: current_account.id) if current_account && params[:mine] == 'true'
    @awards = @awards.order(created_at: :desc).page(params[:page]).decorate
  end

  def create
    quantity = params[:award][:quantity]&.delete(',')
    result = AwardSlackUser.call(project: @project, issuer: current_account, award_type_id: params[:award][:award_type_id], channel_id: params[:award][:channel_id], uid: params[:award][:uid], quantity: quantity, description: params[:award][:description])
    if result.success?
      award = result.award
      authorize award
      if award.save
        account = award.account
        award.send_award_notifications
        award.send_confirm_email
        generate_message(award)
        session[:last_award_id] = award.id if account&.ethereum_wallet?
        account&.update new_award_notice: true
        redirect_to project_overview_path(award.project)
      else
        render_back(award.errors.full_messages.first)
      end
    else
      render_back(result.message)
    end
  end

  def confirm
    if current_account
      award = Award.find_by confirm_token: params[:token]
      if award
        flash[:notice] = confirm_message if award.confirm!(current_account)
        redirect_to project_overview_path(award.project)
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

  def preview
    uid = params[:uid]
    channel_id = params[:channel_id]
    quantity = params[:quantity]&.delete(',')
    award_type = AwardType.find_by(id: params[:award_type_id])
    if award_type && quantity && uid
      @total_amount = award_type.amount * BigDecimal(quantity)
      if channel_id.blank?
        account = Account.where('lower(email)=?', uid.downcase).first
      else
        channel = Channel.find_by id: channel_id
        account = Account.find_or_create_for_authentication(uid, channel).first
      end
      @recipient_address = account&.ethereum_wallet
      project  = Project.find_by(id: params[:project_id])
      @unit    = project&.token_symbol
      @unit  ||= Project.coin_types[project&.coin_type]
      @network = project&.ethereum_network
    end
    render layout: false
  end

  def update_transaction_address
    @award = @project.awards.find params[:id]
    @award.update! ethereum_transaction_address: params[:tx]
    @award = @award.decorate
    render layout: false
  end

  private

  def generate_message(award)
    flash[:notice] = if !award.self_issued? && award.decorate.recipient_address.blank?
      "The award recipient hasn't entered a blockchain address for us to send the award to. When the recipient enters their blockchain address you will be able to approve the token transfer on the awards page."
    else
      "Successfully sent award to #{award.decorate.recipient_display_name}"
    end
  end

  def award_params
    params.require(:award).permit(:uid, :quantity, :description)
  end

  def render_back(msg)
    authorize @project
    @award = Award.new(award_params)
    @award.channel_id = params[:award][:channel_id]
    @award.award_type_id = params[:award][:award_type_id]
    @award.email = params[:award][:uid] unless @award.channel_id
    awardable_types_result = GetAwardableTypes.call(account: current_account, project: @project)
    @awardable_types = awardable_types_result.awardable_types
    @can_award = awardable_types_result.can_award
    flash[:error] = "Failed sending award - #{msg}"
    render template: 'projects/show'
  end

  def confirm_message
    if current_account.ethereum_wallet.present?
      "Congratulations, you just claimed your award! Your Ethereum address is #{view_context.link_to current_account.ethereum_wallet, current_account.decorate.etherscan_address} you can change your Ethereum address on your #{view_context.link_to('account page', show_account_path)}. The project owner can now issue your Ethereum tokens."
    else
      "Congratulations, you just claimed your award! Be sure to enter your Ethereum Adress on your #{view_context.link_to('account page', show_account_path)} to receive your tokens."
    end
  end

  def project_overview_path(project)
    project.unlisted? ? unlisted_project_path(project.long_id) : project_path(project)
  end
end
