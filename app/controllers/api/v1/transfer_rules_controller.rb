class Api::V1::TransferRulesController < Api::V1::ApiController
  include Api::V1::Concerns::AuthorizableByProjectPolicy
  include Api::V1::Concerns::AuthorizableByMissionKey
  include Api::V1::Concerns::RequiresAnAuthorization

  # GET /api/v1/projects/1/transfer_rules
  def index
    fresh_when transfer_rules, public: true
  end

  # GET /api/v1/projects/1/transfer_rules/1
  def show
    fresh_when transfer_rule, public: true
  end

  # POST /api/v1/projects/1/transfer_rules
  def create
    transfer_rule = project.token.transfer_rules.create(transfer_rule_params)

    if transfer_rule.save
      @transfer_rule = transfer_rule

      render 'show.json', status: :created
    else
      @errors = transfer_rule.errors

      render 'api/v1/error.json', status: :bad_request
    end
  end

  # DELETE /api/v1/projects/1/transfer_rules/1
  def destroy
    transfer_rule.destroy
    render 'index.json', status: :ok
  end

  private

    def project
      @project ||= project_scope.find(params[:project_id])
    end

    def transfer_rules
      @transfer_rules ||= paginate(project.token.transfer_rules.not_outdated)
    end

    def transfer_rule
      @transfer_rule ||= project.token.transfer_rules.not_outdated.find(params[:id])
    end

    def transfer_rule_params
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transfer_rule, {}).permit(
        :sending_group_id,
        :receiving_group_id,
        :lockup_until
      )
    end
end
