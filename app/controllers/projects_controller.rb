class ProjectsController < ApplicationController
  def index
    @projects = policy_scope(Project)
  end

  def new
    @project = Project.new
    authorize @project
    3.times { @project.reward_types.build }
  end

  def create
    # there could be multiple authentications... maybe this should be a drop down box to select which team
    # you are creating this project for if we actually allow multiple, simultaneous auths
    # instead of assuming its the first in db order
    slack_team_id = current_account.authentications.find_by(provider: "slack").slack_team_id

    project = Project.new(project_params.merge(owner_account: current_account, slack_team_id: slack_team_id))
    authorize project
    project.save!
    flash[:notice] = "Project created"
    redirect_to project_path(project)
  end

  def show
    @project = Project.find(params[:id])
    authorize @project
  end

  def edit
    @project = Project.includes(:reward_types).find(params[:id])
    authorize @project
  end

  def update
    @project = Project.find(params[:id])
    @project.attributes = project_params
    authorize @project
    @project.save!
    flash[:notice] = "Project updated"
    respond_with @project, location: project_path(@project)
  end

  private

  def project_params
    params.require(:project).permit(:title, :description, :tracker, :public, reward_types_attributes: [:id, :name, :suggested_amount])
  end
end
