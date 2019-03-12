class ProjectsController < ApplicationController
  skip_before_action :require_login, except: %i[new edit create update update_status landing]
  skip_after_action :verify_authorized, only: %i[teams landing]
  before_action :assign_current_account

  layout 'react', only: %i[show]

  def landing
    if current_account
      check_account_info
      @my_projects = current_account.projects.unarchived.with_last_activity_at.limit(6).decorate
      @archived_projects = current_account.projects.archived.with_last_activity_at.limit(6).decorate
      @team_projects = current_account.other_member_projects.unarchived.with_last_activity_at.limit(6).decorate
    end
    @my_project_contributors = TopContributors.call(projects: @my_projects).contributors
    @team_project_contributors = TopContributors.call(projects: @team_projects).contributors
    @archived_project_contributors = TopContributors.call(projects: @archived_projects).contributors
  end

  def index
    @projects = policy_scope(Project)

    if params[:query].present?
      @projects = @projects.where(['projects.title ilike :query OR projects.description ilike :query', query: "%#{params[:query]}%"])
    end
    @projects = @projects.order(updated_at: :desc).includes(:account).page(params[:page]).per(9)

    @project_contributors = TopContributors.call(projects: @projects).contributors
  end

  def new
    assign_slack_channels

    @project = current_account.projects.build(public: false,
                                              maximum_tokens: 1_000_000,
                                              maximum_royalties_per_month: 50_000,
                                              mission_id: params[:mission_id])
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
    authorize @project
  end

  def create
    @project = current_account.projects.build project_params
    @project.long_id = params[:long_id] || SecureRandom.hex(20)
    authorize @project
    if @project.save
      flash[:notice] = 'Project created'
      redirect_to project_detail_path
    elsif @project.errors&.details&.dig(:long_id)&.any? { |e| e[:error] == :taken }
      flash[:error] = 'Project already created'
      redirect_to projects_path
    else
      @error = 'Project saving failed, please correct the errors below'
      assign_slack_channels
      render :new
    end
  end

  def show
    @project = Project.listed.includes(:award_types).find(params[:id]).decorate
    authorize @project
    set_award

    token = @project.mission.token.decorate

    contributors_number = @project.contributors_by_award_amount.size
    award_data = GetContributorData.call(project: @project).award_data
    chart_data = award_data[:contributions_summary_pie_chart].map { |award| award[:net_amount] }.sort{ |a, b| b <=> a }

    render component: 'Project', props: {
      interested: current_account&.interested?(@project.id),
      project_data: @project.as_json(only: %i[id title description]).merge(
        image_url: @project.image.present? ? 'url(' + Refile.attachment_url(@project, :image) + ')' : nil,
        youtube_url: @project.video_url ? @project.youtube_id : nil,
        default_image_url: helpers.image_url('defaul_project.jpg'),
        owner: [@project.account.first_name, @project.account.last_name].join(' '),
        token_percentage: @project.maximum_tokens.positive? ? 100 * @project.total_awarded / @project.maximum_tokens : 0,
        maximum_tokens: @project.maximum_tokens_pretty,
        awarded_tokens: @project.total_awarded_pretty,
        team_leader: contributor_props(@project.account),
        contributors_number: contributors_number,
        contributors: @project.top_contributors.map { |contributor| contributor_props(contributor) },
        chart_data: chart_data
      ),
      mission_data: @project.mission.as_json(only: %i[id name]).merge(
        image_url: @project.mission.image.present? ? Refile.attachment_url(@project.mission, :image, :fill, 150, 100) : nil
      ),
      token_data: token.as_json(only: %i[name symbol coin_type]).merge(
        image_url: token.logo_image.present? ? Refile.attachment_url(token, :logo_image, :fill, 25, 18) : nil,
        contract_url: token.ethereum_contract_explorer_url
      ),
      csrf_token: form_authenticity_token
    }
  end

  def unlisted
    @project = Project.includes(:award_types).find_by(long_id: params[:long_id])&.decorate
    authorize @project
    if @project&.access_unlisted?(current_account)
      set_award
      render :show
    elsif @project&.can_be_access?(current_account)
      redirect_to project_path(@project)
    end
  end

  def edit
    @project = current_account.projects.includes(:award_types).find(params[:id]).decorate
    @project.channels.build if current_account.teams.any?
    @project.long_id ||= SecureRandom.hex(20)
    authorize @project
    assign_slack_channels
    @current_section = '#general'
  end

  def update
    @project = current_account.projects.includes(:award_types, :channels).find(params[:id])
    @project.long_id ||= params[:long_id] || SecureRandom.hex(20)
    authorize @project
    if @project.update project_params
      @notice = 'Project updated'
    else
      @error = 'Project update failed, please correct the errors below'
    end
    @project = @project.decorate
    assign_slack_channels
    @current_section = params[:current_section]
    render :edit
  end

  def update_status
    @project = Project.find(params[:project_id])
    authorize @project

    begin
      @project.update(status: params[:status])
      render json: { message: 'Successfully updated.' }, status: :ok
    rescue ArgumentError
      render json: { message: 'Invalid Status' }, status: :unprocessable_entity
    end
  end

  private

  def project_params
    result = params.require(:project).permit(
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
      :coin_type,
      :exclusive_contributions,
      :legal_project_owner,
      :minimum_payment,
      :minimum_revenue,
      :require_confidentiality,
      :royalty_percentage,
      :maximum_royalties_per_month,
      :license_finalized,
      :denomination,
      :mission_id,
      :visibility,
      :ethereum_network,
      :ethereum_contract_address,
      :blockchain_network,
      :contract_address,
      :token_symbol,
      :decimal_places,
      :status,
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
    result[:revenue_sharing_end_date] = DateTime.strptime(result[:revenue_sharing_end_date], '%m/%d/%Y') if result[:revenue_sharing_end_date].present?
    result
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
    last_award = @project.awards.last
    @award = Award.new channel: last_award&.channel, award_type: last_award&.award_type
    awardable_types_result = GetAwardableTypes.call(account: current_account, project: @project)
    @awardable_types = awardable_types_result.awardable_types
    @can_award = awardable_types_result.can_award
  end

  def project_detail_path
    @project.unlisted? ? unlisted_project_path(@project.long_id) : project_path(@project)
  end

  def contributor_props(account)
    account.as_json(only: %i[id nickname first_name last_award]).merge(
      image_url: helpers.account_image_url(account, 44),
      specialty: Account.specialties[account.specialty]
    )
  end
end
