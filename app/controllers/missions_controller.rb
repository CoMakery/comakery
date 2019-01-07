class MissionsController < ApplicationController
  layout 'react'
  before_action :find_mission_by_id, only: %i[edit update update_status destroy]
  before_action :set_generic_props, only: %i[new show edit]

  def index
    @missions = policy_scope(Mission).map do |m|
      m.serialize.merge(
        token_name: m.token&.name,
        token_symbol: m.token&.symbol,
        projects: m.projects.as_json(only: %i[id title status])
      )
    end

    render component: 'MissionIndex', props: { csrf_token: form_authenticity_token, missions: @missions }
  end

  def new
    @mission = Mission.new
    authorize @mission

    @props[:mission] = @mission&.serialize
    render component: 'MissionForm', props: @props
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
    render component: 'MissionForm', props: @props
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

  private

  def mission_params
    params.require(:mission).permit(:name, :subtitle, :description, :logo, :image, :token_id, :status)
  end

  def find_mission_by_id
    @mission = Mission.find(params[:id])
  end

  def set_generic_props
    @props = {
      tokens: Token.all.map { |token| [token.name, token.id.to_s] },
      mission: @mission&.serialize,
      form_url: missions_path,
      form_action: 'POST',
      url_on_success: missions_path,
      csrf_token: form_authenticity_token
    }
  end
end
