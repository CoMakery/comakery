class AwardsController < ApplicationController
  before_action :assign_project, only: %i[create index]
  before_action :assign_current_auth, only: [:index]
  skip_before_action :require_login, only: :index

  def index
    authorize @project, :show_contributions?
    @awards = @project.awards.page(params[:page]).decorate
    @award_data = GetAwardData.call(authentication: current_account&.slack_auth, project: @project).award_data
  end

  def create
    result = AwardSlackUser.call(project: @project,
                                 slack_user_id: params[:award][:slack_user_id],
                                 issuer: current_account,
                                 award_params: award_params.except(:slack_user_id))
    if result.success?
      award = result.award
      authorize award
      award.save!
      CreateEthereumAwards.call(award: award)

      current_account.send_award_notifications(award: award)

      flash[:notice] = "Successfully sent award to #{award.recipient_display_name}"
      redirect_to project_path(award.project)
    else
      fail_and_redirect(result.message)
    end
  rescue Pundit::NotAuthorizedError
    fail_and_redirect('Not authorized')
  end

  def fail_and_redirect(message)
    skip_authorization
    flash[:error] = "Failed sending award - #{message}"
    redirect_back fallback_location: root_path
  end

  private

  def award_params
    params.require(:award).permit(:slack_user_id, :award_type_id, :quantity, :description, :page)
  end

  def assign_project
    @project = policy_scope(Project).find(params[:project_id]).decorate
  end

  def assign_current_auth
    @current_auth = current_account&.slack_auth&.decorate
  end
end
