class ProjectsController < ApplicationController
  skip_before_action :require_login, except: %i[new edit create update update_status landing]
  skip_after_action :verify_authorized, only: %i[teams landing]
  before_action :assign_current_account
  before_action :assign_project, only: %i[edit show update awards]
  before_action :assign_project_by_long_id, only: %i[unlisted]
  before_action :set_award, only: %i[show unlisted]
  before_action :set_tokens, only: %i[new edit]
  before_action :set_missions, only: %i[new edit]
  before_action :set_visibilities, only: %i[new edit]
  before_action :set_teams, only: %i[new edit]
  before_action :set_generic_props, only: %i[new edit]
  before_action :set_show_props, only: %i[show unlisted]

  layout 'react', only: %i[show unlisted new edit]

  def landing
    if current_account
      @my_projects = current_account.projects.unarchived.with_last_activity_at.limit(6).decorate
      @archived_projects = current_account.projects.archived.with_last_activity_at.limit(6).decorate
      @team_projects = current_account.other_member_projects.unarchived.with_last_activity_at.limit(6).decorate
      @interested_projects = current_account.projects_interested.unarchived.with_last_activity_at.limit(6).decorate
    end
    @my_project_contributors = TopContributors.call(projects: @my_projects).contributors
    @team_project_contributors = TopContributors.call(projects: @team_projects).contributors
    @interested_project_contributors = TopContributors.call(projects: @interested_projects).contributors
    @archived_project_contributors = TopContributors.call(projects: @archived_projects).contributors
  end

  def awards
    authorize @project, :show_contributions?
    @awards = @project.awards.completed
    @awards = @awards.where(account_id: current_account.id) if current_account && params[:mine] == 'true'
    @awards = @awards.order(created_at: :desc).page(params[:page]).decorate

    render 'awards/index'
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
    @project = current_account.projects.build
    @project.channels.build if current_account.teams.any?
    @project.long_id ||= SecureRandom.hex(20)

    authorize @project

    @props[:project] = @project.serializable_hash.merge(
      url: "https://www.comakery.com/p/#{@project.long_id}",
      mission_id: params[:mission_id] ? Mission.find(params[:mission_id])&.id : nil
    )
    render component: 'ProjectForm', props: @props
  end

  def create
    @project = current_account.projects.build project_params
    @project.public = false
    @project.long_id ||= SecureRandom.hex(20)

    authorize @project

    if @project.save
      set_generic_props
      camelize_props
      render json: { id: @project.id, props: @props }, status: :ok
    else
      errors  = @project.errors.messages.map { |k, v| ["project[#{k}]", v.to_sentence] }.to_h
      message = @project.errors.full_messages.join(', ')
      render json: { message: message, errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    authorize @project
    render component: 'Project', props: @props
  end

  def unlisted
    authorize @project
    render component: 'Project', props: @props
  end

  def edit
    @project.channels.build if current_account.teams.any?
    @project.long_id ||= SecureRandom.hex(20)
    authorize @project

    @props[:form_action] = 'PATCH'
    @props[:form_url]    = project_path(@project)

    render component: 'ProjectForm', props: @props
  end

  def update
    @project = current_account.projects.find(params[:id])
    @project.long_id ||= params[:long_id] || SecureRandom.hex(20)
    authorize @project

    if @project.update project_params
      set_generic_props
      camelize_props
      render json: { message: 'Project updated', id: @project.id, props: @props }, status: :ok
    else
      errors  = @project.errors.messages.map { |k, v| [k, v.to_sentence] }.to_s
      message = @project.errors.full_messages.join(', ')
      render json: { message: message, errors: errors }, status: :unprocessable_entity
    end
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

  def assign_project_by_long_id
    @project = Project.find_by(long_id: params[:long_id])&.decorate

    return redirect_to('/404.html') unless @project
    return redirect_to(project_path(@project)) unless @project.unlisted?
  end

  def set_tokens
    @tokens = Token.listed.or(Token.where(id: @project&.token&.id)).pluck(:name, :id).append(['No Token', '']).reverse.to_h
  end

  def set_missions
    @missions = Mission.all.pluck(:name, :id).append(['No Mission', '']).reverse.to_h
  end

  def set_visibilities
    @visibilities = Project.visibilities.keys
  end

  def set_teams
    @teams = current_account&.authentication_teams&.map do |a_team|
      {
        team: "[#{a_team.team.provider}] #{a_team.team.name}",
        team_id: a_team.team.id.to_s,
        discord: a_team.team.discord?,
        channels: a_team.channels&.map do |channel|
          {
            channel: a_team.team.discord? ? channel.first.to_s : channel,
            channel_id: a_team.team.discord? ? channel.second.to_s : channel
          }
        end
      }
    end
  end

  def set_generic_props
    @props = {
      project: @project&.serializable_hash&.merge(
        {
          square_image_url: @project&.square_image&.present? ? Refile.attachment_url(@project, :square_image, :fill, 1200, 800) : nil,
          panoramic_image_url: @project&.panoramic_image&.present? ? Refile.attachment_url(@project, :panoramic_image, :fill, 1500, 300) : nil,
          mission_id: @project&.mission&.id,
          token_id: @project&.token&.id,
          channels: @project&.channels&.map do |channel|
            {
              channel_id: channel&.channel_id&.to_s,
              team_id: channel&.team&.id&.to_s,
              id: channel&.id
            }
          end,
          url: unlisted_project_url(@project.long_id)
        }
      ),
      tokens: @tokens,
      decimal_places: Token.select(:id, :decimal_places),
      missions: @missions,
      visibilities: @visibilities,
      teams: @teams&.reject { |t| t[:channels].blank? },
      discord_bot_url: if @teams&.any? { |t| t[:discord] && t[:channels].empty? }
                         Comakery::Discord.new.add_bot_link
                       end,
      license_url: contribution_licenses_path(type: 'CP'),
      terms_readonly: @project&.terms_readonly?,
      form_url: projects_path,
      form_action: 'POST',
      csrf_token: form_authenticity_token,
      project_for_header: project_header,
      mission_for_header: @project&.mission&.decorate&.header_props
    }
  end

  def project_header
    @project ? @project.decorate.header_props : { image_url: helpers.image_url('defaul_project.jpg') }
  end

  def set_show_props
    @props = {
      tasks_by_specialty: @project.ready_tasks_by_specialty.map do |specialty, awards|
        [specialty&.name || 'General', awards.map { |task| task_to_props(task).merge(allowed_to_start: policy(task).start?) }]
      end,
      interested: current_account&.interested?(@project.id),
      specialty_interested: [*1..8].map { |specialty_id| current_account&.specialty_interested?(@project.id, specialty_id) },
      project_data: project_props(@project),
      token_data: token_props(@project&.token&.decorate),
      csrf_token: form_authenticity_token,
      my_tasks_path: my_tasks_path(project_id: @project.id),
      editable: policy(@project).edit?,
      project_for_header: @project.decorate.header_props,
      mission_for_header: @project&.mission&.decorate&.header_props
    }
  end

  def camelize_props
    @props.deep_transform_keys! { |key| key.to_s.camelize(:lower) }
  end

  def project_params
    result = params.require(:project).permit(
      :contributor_agreement_url,
      :description,
      :square_image,
      :panoramic_image,
      :maximum_tokens,
      :token_id,
      :mission_id,
      :long_id,
      :title,
      :tracker,
      :video_url,
      :payment_type,
      :exclusive_contributions,
      :legal_project_owner,
      :minimum_payment,
      :require_confidentiality,
      :confidentiality,
      :license_finalized,
      :visibility,
      :status,
      channels_attributes: %i[
        _destroy
        id
        team_id
        channel_id
      ]
    )
    result
  end

  def assign_current_account
    @current_account_deco = current_account&.decorate
  end

  def set_award
    last_award = @project.awards&.completed&.last
    @award = Award.new channel: last_award&.channel, award_type: last_award&.award_type
    awardable_types_result = GetAwardableTypes.call(account: current_account, project: @project)
    @awardable_types = awardable_types_result.awardable_types
    @can_award = awardable_types_result.can_award
  end

  def project_detail_path
    @project.unlisted? ? unlisted_project_path(@project.long_id) : project_path(@project)
  end

  def contributor_props(account)
    account.as_json(only: %i[id nickname first_name last_name linkedin_url github_url dribble_url behance_url]).merge(
      image_url: helpers.account_image_url(account, 68),
      specialty: account.specialty&.name
    )
  end

  def project_props(project)
    contributors_number = @project.contributors_by_award_amount.size
    award_data = GetContributorData.call(project: @project).award_data
    chart_data = award_data[:contributions_summary_pie_chart].map { |award| award[:net_amount] }.sort { |a, b| b <=> a }

    project.as_json(only: %i[id title require_confidentiality]).merge(
      description_header: project.description.split('.').first,
      description_html: Comakery::Markdown.to_html(project.description.split('.')[1..-1]&.join('.')),
      show_contributions: policy(project).show_contributions?,
      square_image_url: Refile.attachment_url(project, :square_image) || helpers.image_url('defaul_project.jpg'),
      panoramic_image_url: Refile.attachment_url(project, :panoramic_image) || helpers.image_url('defaul_project.jpg'),
      video_id: project.video_id,
      owner: project.account.decorate.name,
      token_percentage: project.percent_awarded_pretty,
      maximum_tokens: project.maximum_tokens,
      awarded_tokens: project.total_awarded_pretty,
      team_leader: contributor_props(project.account),
      contributors_number: contributors_number,
      contributors: project.top_contributors.map { |contributor| contributor_props(contributor) },
      chart_data: chart_data,
      stats: project.stats
    )
  end

  def token_props(token)
    if token.present?
      token.as_json(only: %i[name symbol coin_type]).merge(
        image_url: token.logo_image.present? ? Refile.attachment_url(token, :logo_image, :fill, 25, 18) : nil,
        contract_url: token.ethereum_contract_explorer_url
      )
    end
  end

  def mission_props(mission)
    if mission.present?
      mission.as_json(only: %i[id name]).merge(
        logo_url: mission.image.present? ? Refile.attachment_url(mission, :logo, :fill, 100, 100) : nil,
        mission_url: mission_path(mission)
      )
    end
  end
end
