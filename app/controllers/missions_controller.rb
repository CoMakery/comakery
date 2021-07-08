class MissionsController < ApplicationController
  skip_before_action :require_login, only: %i[show]

  before_action :find_mission_by_id, only: %i[show edit update]
  before_action :set_form_props, only: %i[new edit]
  before_action :set_mission_props, only: %i[show]
  before_action :set_missions, only: %i[index rearrange]

  def index
    authorize Mission.new
    @props = { csrf_token: form_authenticity_token, missions: @missions }
  end

  def new
    @mission = Mission.new
    authorize @mission

    @props[:mission] = @mission&.serialize
  end

  def show
    authorize @mission

    @meta_title = 'CoMakery Mission'
    @meta_desc = "#{@mission.name}: #{@mission.description}"
    @meta_image = Attachment::GetPath.call(attachment: @mission.image)
  end

  def create
    @mission = Mission.new(mission_params)

    authorize @mission

    if @mission.save
      render json: { id: @mission.id, message: 'Successfully created.' }, status: :ok
    else
      errors = @mission.errors.as_json
      errors.each { |key, value| errors[key] = value.to_sentence }
      render json: { message: @mission.errors.full_messages.join(', '), errors: errors }, status: :unprocessable_entity
    end
  end

  def edit
    authorize @mission

    @props[:form_url] = mission_path(@mission)
    @props[:form_action] = 'PATCH'
  end

  def update
    authorize @mission

    if @mission.update(mission_params)
      render json: { message: 'Successfully updated.' }, status: :ok
    else
      errors = @mission.errors.as_json
      errors.each { |key, value| errors[key] = value.to_sentence }
      render json: { message: @mission.errors.full_messages.join(', '), errors: errors }, status: :unprocessable_entity
    end
  end

  def rearrange
    authorize Mission.new
    # rearrange feature
    mission_ids = params[:mission_ids]
    display_orders = params[:display_orders]
    direction = params[:direction].to_i
    length = mission_ids.length

    (0..length - 1).each do |index|
      mission = Mission.find(mission_ids[index])
      mission.display_order = display_orders[(index + direction + length) % length]
      mission.save
    end

    render json: { missions: @missions, message: 'Successfully updated.' }, status: :ok
  end

  private

    def mission_params
      params.require(:mission).permit(
        :name,
        :subtitle,
        :description,
        :logo,
        :image,
        :status,
        :whitelabel,
        :whitelabel_domain,
        :whitelabel_logo,
        :whitelabel_logo_dark,
        :whitelabel_favicon,
        :whitelabel_contact_email,
        :whitelabel_api_public_key,
        :wallet_recovery_api_public_key
      )
    end

    def find_mission_by_id
      @mission = Mission.find(params[:id])
    end

    def contributor_props(account, project)
      a = account.decorate.serializable_hash(
        only: %i[id nickname first_name last_name linkedin_url github_url dribble_url behance_url],
        include: :specialty,
        methods: :image_url
      )

      a['specialty'] ||= {}

      if project.account == account || project.project_admins.include?(account)
        a['specialty']['name'] = 'Team Leader'
      elsif !project.contributors_distinct.include?(account)
        a['specialty']['name'] = 'Interested'
      end

      a
    end

    def project_props(project)
      project.as_json(only: %i[id title]).merge(
        description: project.description_text_truncated(500),
        image_url: Attachment::GetPath.call(attachment: project.panoramic_image).path,
        square_url: GetImageVariantPath.call(
          attachment: project.square_image,
          resize_to_fill: [800, 800]
        ).path,
        default_image_url: helpers.image_url('default_project.jpg'),
        team_size: project.team_size,
        team: project.team_top.map { |contributor| contributor_props(contributor, project) }
      )
    end

    def project_leaders(mission)
      project_counts = mission.leaders.group(:account_id).count

      mission.leaders.distinct.limit(4).map do |account|
        account.serializable_hash.merge(
          count: project_counts[account.id],
          project_name: mission.public_projects.find_by(account_id: account.id).title,
          image_url: helpers.account_image_url(account, 240)
        )
      end
    end

    def project_tokens(mission)
      project_counts = mission.tokens.group(:token_id).count

      {
        tokens:
          mission.tokens.distinct.limit(4).map do |token|
            token.serializable_hash.merge(
              count: project_counts[token.id],
              project_name: mission.public_projects.find_by(token_id: token.id).title,
              logo_url: GetImageVariantPath.call(attachment: token.logo_image, resize_to_fill: [30, 30]).path
            )
          end,
        token_count: mission.tokens.distinct.size
      }
    end

    def set_mission_props # rubocop:todo Metrics/CyclomaticComplexity
      projects = @mission.public_projects.order('project_roles_count DESC').includes(:token, :accounts, :award_types, :ready_award_types, :account, contributors_distinct: [:specialty])

      @props = {
        mission: @mission&.serializable_hash&.merge(mission_images)&.merge({ stats: @mission.stats }),
        leaders: project_leaders(@mission),
        tokens: project_tokens(@mission),
        new_project_url: new_project_path(mission_id: @mission.id),
        csrf_token: form_authenticity_token,
        projects: projects.map do |project|
          {
            project_url: project_url(project),
            editable: current_account&.id == project.account_id,
            project_follower: project.accounts.include?(current_account),
            project_data: project_props(project.decorate),
            token_data: project.token&.as_json(only: %i[name])&.merge(
              logo_url: GetImageVariantPath.call(attachment: project.token&.logo_image, resize_to_fill: [30, 30]).path
            ),
            stats: project.stats
          }
        end
      }
    end

    def set_form_props
      @props = {
        mission: @mission&.serializable_hash&.merge(mission_images),
        form_url: missions_path,
        form_action: 'POST',
        url_on_success: missions_path,
        csrf_token: form_authenticity_token
      }
    end

    def mission_images
      {
        logo_url: mission_image_path(@mission.logo, 800, 800),
        image_url: mission_image_path(@mission.logo, 1200, 800),
        whitelabel_logo_url: mission_image_path(@mission.logo, 1000, 200),
        whitelabel_logo_dark_url: mission_image_path(@mission.logo, 1000, 200),
        whitelabel_favicon_url: mission_image_path(@mission.logo, 64, 64)
      }
    end

    def mission_image_path(image, width, height)
      GetImageVariantPath.call(
        attachment: image,
        resize_to_fill: [width, height]
      ).path
    end

    def set_missions
      @missions =
        policy_scope(Mission)
        .with_all_attached_images
        .includes(:public_projects, :unarchived_projects).map do |m|
          m.serialize.merge(
            projects: m.public_projects.as_json(only: %i[id title status])
          )
        end
    end
end
