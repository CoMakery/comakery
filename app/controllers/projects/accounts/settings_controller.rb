class Projects::Accounts::SettingsController < ApplicationController
  skip_after_action :verify_authorized, :verify_policy_scoped

  def show
    @project_role = ProjectRole.find_by(project_id: params[:project_id], account_id: params[:account_id])

    @project_policy = ProjectPolicy.new(current_account, @project_role.project)
  end
end
