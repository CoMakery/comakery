class ProjectsController < ApplicationController
  skip_before_action :require_login, except: :new
  before_action :assign_current_account

  def landing
    if current_account
      check_account_info
      @my_projects = current_account.projects.unarchived.with_last_activity_at.limit(6).decorate
      @archived_projects = current_account.projects.archived.with_last_activity_at.limit(6).decorate
      @team_projects = current_account.other_member_projects.with_last_activity_at.limit(6).decorate
    else
      @archived_projects = []
      @team_projects = []
      @my_projects = Project.public_listed.featured.with_last_activity_at.limit(6).decorate
    end
    @my_project_contributors = TopContributors.call(projects: @my_projects).contributors
    @team_project_contributors = TopContributors.call(projects: @team_projects).contributors
    @archived_project_contributors = TopContributors.call(projects: @archived_projects).contributors
  end

  def index
    @projects = if current_account
      current_account.accessable_projects.with_last_activity_at
    else
      Project.public_listed.with_last_activity_at
    end

    if params[:query].present?
      @projects = @projects.where(['projects.title ilike :query OR projects.description ilike :query', query: "%#{params[:query]}%"])
    end
    @projects = @projects.decorate
    @project_contributors = TopContributors.call(projects: @projects).contributors
  end

  def new
    assign_slack_channels

    @project = current_account.projects.build(public: false,
                                              maximum_tokens: 1_000_000,
                                              maximum_royalties_per_month: 50_000)
    @project.award_types.build(name: 'Thanks', amount: 10)
    @project.award_types.build(name: 'Software development hour', amount: 100)
    @project.award_types.build(name: 'Graphic design hour', amount: 100)
    @project.award_types.build(name: 'Product management hour', amount: 100)
    @project.award_types.build(name: 'Marketing hour', amount: 100)

    @project.award_types.build(name: 'Expert software development hour', amount: 150)
    @project.award_types.build(name: 'Expert graphic design hour', amount: 150)
    @project.award_types.build(name: 'Expert product management hour', amount: 150)
    @project.award_types.build(name: 'Expert marketing hour', amount: 150)
    @project.award_types.build(name: 'Blog post (600+ words)', amount: 150)
    @project.award_types.build(name: 'Long form article (2,000+ words)', amount: 2000)
    @project.channels.build if current_account.teams.any?
    @project.long_id ||= SecureRandom.hex(20)
  end

  def create
    @project = current_account.projects.build project_params
    @project.long_id = params[:long_id] || SecureRandom.hex(20)
    if @project.save
      flash[:notice] = 'Project created'
      redirect_to project_detail_path
    else
      flash[:error] = 'Project saving failed, please correct the errors below'
      assign_slack_channels
      render :new
    end
  end

  def show
    @project = Project.listed.includes(:award_types).find(params[:id]).decorate
    set_award
  end

  def unlisted
    @project = Project.includes(:award_types).find_by(long_id: params[:long_id])&.decorate
    if @project&.access_unlisted?(current_account)
      set_award
      render :show
    elsif @project&.can_be_access?(current_account)
      redirect_to project_path(@project)
    else
      redirect_to root_path
    end
  end

  def edit
    @project = current_account.projects.includes(:award_types).find(params[:id])
    @project.channels.build if current_account.teams.any?
    @project.long_id ||= SecureRandom.hex(20)
    assign_slack_channels
  end

  def update
    @project = current_account.projects.includes(:award_types, :channels).find(params[:id])
    @project.long_id ||= params[:long_id] || SecureRandom.hex(20)
    if @project.update project_params
      flash[:notice] = 'Project updated'
      respond_with @project, location: project_detail_path
    else
      flash[:error] = 'Project update failed, please correct the errors below'
      assign_slack_channels
      render :edit
    end
  end

  def transfer_tokens
    @project = current_account.projects.find(params[:id])
  end

  private

  def project_params
    params.require(:project).permit(
      :revenue_sharing_end_date,
      :contributor_agreement_url,
      :description,
      :ethereum_enabled,
      :image,
      :maximum_tokens,
      :title,
      :tracker,
      :video_url,
      :payment_type,
      :exclusive_contributions,
      :legal_project_owner,
      :minimum_payment,
      :minimum_revenue,
      :require_confidentiality,
      :royalty_percentage,
      :maximum_royalties_per_month,
      :license_finalized,
      :denomination,
      :visibility,
      :ethereum_contract_address,
      :token_symbol,
      award_types_attributes: %i[
        _destroy
        amount
        community_awardable
        id
        name
        description
        disabled
      ],
      channels_attributes: %i[id team_id channel_id _destroy]
    )
  end

  def assign_slack_channels
    @providers = current_account.teams.map(&:provider).uniq
    @provider_data = {}
    @providers.each do |provider|
      teams = current_account.teams.where(provider: provider)
      team_data = []
      teams.each do |_team|
        team_data
      end
      @provider_data[provider] = teams
    end
    # result = GetSlackChannels.call(current_account: current_account)
    # @slack_channels = result.channels
  end

  def assign_current_account
    @current_account_deco = current_account&.decorate
  end

  def set_award
    @award = Award.new
    awardable_types_result = GetAwardableTypes.call(account: current_account, project: @project)
    @awardable_types = awardable_types_result.awardable_types
    @can_award = awardable_types_result.can_award
    @award_data = GetAwardData.call(account: current_account, project: @project).award_data
  end

  def project_detail_path
    @project.unlisted? ? unlisted_project_path(@project.long_id) : project_path(@project)
  end
end
