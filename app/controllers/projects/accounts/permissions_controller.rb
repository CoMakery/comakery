class Projects::Accounts::PermissionsController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  skip_after_action :verify_authorized, :verify_policy_scoped

  before_action :find_project_role

  def show
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          :account_permissions_modal,
          partial: 'projects/accounts/permissions/modal',
          locals: { project_role: @project_role }
        )
      end
    end
  end

  def update
    authorize(@project_role, :update?)

    respond_to do |format|
      if @project_role.update(role: params[:project_role][:role])
        format.json { render json: { message: 'Permissions successfully updated' }, status: :ok }
      else
        format.json { render json: { errors: @project_role.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

    def find_project_role
      @project_role = ProjectRole.find(params[:id])
    end
end
