class AwardsController < ApplicationController
  before_action :assign_project, only: %i[create index]
  skip_before_action :require_login, only: %i[index confirm]
  skip_after_action :verify_authorized

  def index
    authorize @project, :show_contributions?
    @awards = @project.awards
    @awards = @awards.where(account_id: current_account.id) if current_account && params[:mine] == 'true'
    @awards = @awards.order(created_at: :desc).page(params[:page]).decorate
  end

  def create
    result = AwardSlackUser.call(project: @project, issuer: current_account, award_type_id: params[:award][:award_type_id], channel_id: params[:award][:channel_id], uid: params[:award][:uid], quantity: params[:award][:quantity], description: params[:award][:description])
    if result.success?
      award = result.award
      authorize award
      award.save!
      if award.channel
        CreateEthereumAwards.call(award: award)
        award.send_award_notifications
      end
      award.send_confirm_email
      flash[:notice] = "Successfully sent award to #{award.decorate.recipient_display_name}"
      redirect_to project_path(award.project)
    else
      fail_and_redirect(result.message)
    end
  rescue Pundit::NotAuthorizedError
    fail_and_redirect('Not authorized')
  end

  def confirm
    if current_account
      award = Award.find_by confirm_token: params[:token]
      if award
        award.confirm!(current_account)
        redirect_to project_path(award.project)
      else
        flash[:error] = 'Invalid award token!'
        redirect_to root_path
      end
    else
      session[:award_token] = params[:token]
      redirect_to new_session_path
    end
  end

  def fail_and_redirect(message)
    skip_authorization
    flash[:error] = "Failed sending award - #{message}"
    redirect_back fallback_location: root_path
  end

  private

  def award_params
    params.require(:award).permit(:uid, :quantity, :description)
  end
end
