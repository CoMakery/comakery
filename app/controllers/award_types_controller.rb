class AwardTypesController < ApplicationController
  before_action :assign_project
  before_action :authorize_project_edit
  before_action :set_award_type, only: %i[show edit update destroy]
  before_action :set_form_props, only: %i[new edit]
  before_action :set_index_props, only: [:index]

  layout 'react'

  def index
    render component: 'BatchIndex', props: @props
  end

  def new
    render component: 'BatchForm', props: @props
  end

  def edit
    @props[:form_url] = project_award_type_path(@project, @award_type)
    @props[:form_action] = 'PATCH'

    render component: 'BatchForm', props: @props
  end

  def create
    @award_type = @project.award_types.new(award_type_params)

    if @award_type.save
      set_ok_response
      render json: @ok_response, status: :ok
    else
      set_error_response
      render json: @error_response, status: :unprocessable_entity
    end
  end

  def update
    if @award_type.update(award_type_params)
      set_ok_response
      render json: @ok_response, status: :ok
    else
      set_error_response
      render json: @error_response, status: :unprocessable_entity
    end
  end

  def destroy
    if @award_type.destroy
      redirect_to project_award_types_path, notice: 'Batch destroyed'
    else
      redirect_to project_award_types_path, flash: { error: @award_type.errors.full_messages.join(', ') }
    end
  end

  private

    def authorize_project_edit
      authorize @project, :edit?
    end

    def set_award_type
      @award_type = @project.award_types.find(params[:id])
    end

    def award_type_params
      params.fetch(:batch, {}).permit(
        :specialty_id,
        :name,
        :goal,
        :description,
        :diagram
      )
    end

    def set_index_props
      @props = {
        batches: @project.award_types&.map do |batch|
          batch.serializable_hash.merge(
            diagram_url: Refile.attachment_url(batch ? batch : @project.award_types.new, :diagram, :fill, 300, 300),
            completed_tasks: batch.awards.completed.count,
            total_tasks: batch.awards.count,
            specialty: batch.specialty&.name,
            currency: batch.project.token&.symbol,
            total_amount: batch.awards.sum(:total_amount),
            currency_logo: batch.project.token ? Refile.attachment_url(batch.project.token, :logo_image, :fill, 100, 100) : nil,
            team_pics: batch.project.contributors_distinct.map { |a| helpers.account_image_url(a, 100) },
            edit_path: edit_project_award_type_path(@project, batch),
            destroy_path: project_award_type_path(@project, batch),
            new_task_path: new_project_award_type_award_path(@project, batch),
            tasks: batch.awards&.listed&.map do |task|
              task.serializable_hash.merge(
                batch_name: batch.name,
                currency: batch.project.token&.symbol,
                currency_logo: batch.project.token ? Refile.attachment_url(batch.project.token, :logo_image, :fill, 100, 100) : nil,
                award_path: project_award_type_award_path(@project, batch, task),
                pay_path: awards_project_path(@project),
                clone_path: project_award_type_award_clone_path(@project, batch, task),
                edit_path: edit_project_award_type_award_path(@project, batch, task),
                destroy_path: task.can_be_deleted? && project_award_type_award_path(@project, batch, task)
              )
            end
          )
        end,
        new_batch_path: new_project_award_type_path(@project),
        project: @project.serializable_hash
      }
    end

    def set_form_props
      @props = {
        batch: (@award_type ? @award_type : @project.award_types.new).serializable_hash&.merge(
          diagram_url: Refile.attachment_url(@award_type ? @award_type : @project.award_types.new, :diagram, :fill, 300, 300)
        ),
        project: @project.serializable_hash,
        specialties: Specialty.all.map { |s| [s.name, s.id] }.unshift(['General', nil]).to_h,
        form_url: project_award_types_path,
        form_action: 'POST',
        url_on_success: project_award_types_path,
        project_id: @project.id,
        csrf_token: form_authenticity_token
      }
    end

    def set_ok_response
      @ok_response = {
        id: @award_type.id,
        message: (action_name == 'create' ? 'Batch created' : 'Batch updated')
      }
    end

    def set_error_response
      @error_response = {
        id: @award_type.id,
        message: @award_type.errors.full_messages.join(', '),
        errors: @award_type.errors.messages.map { |k, v| ["award_type[#{k}]", v.to_sentence] }.to_h
      }
    end
end
