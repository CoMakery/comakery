class Api::V1::InterestsController < Api::V1::ApiController
  include Api::V1::Concerns::AuthorizableByMissionKey
  include Api::V1::Concerns::RequiresAnAuthorization
  include Api::V1::Concerns::RequiresSignature
  include Api::V1::Concerns::RequiresWhitelabelMission

  # GET /api/v1/accounts/1/interests
  def index
    fresh_when interests, public: true
  end

  # POST /api/v1/accounts/1/interests
  def create
    interest = Interest.create(
      account: account,
      specialty: account.specialty,
      project: project_scope.find(params.fetch(:body, {}).fetch(:data, {}).fetch(:project_id, nil))
    )

    if interest.save
      interests

      render 'index.json', status: 201
    else
      @errors = interest.errors

      render 'api/v1/error.json', status: 400
    end
  end

  # DELETE /api/v1/accounts/1/interests/1
  def destroy
    interest.interests.find_by!(account: account).destroy
    interests

    render 'index.json', status: 200
  end

  private

    def account
      @account ||= whitelabel_mission.managed_accounts.find_by!(managed_account_id: params[:account_id])
    end

    def interests
      @interests ||= paginate(account.projects_interested.where(mission: whitelabel_mission))
    end

    def interest
      @interest ||= account.projects_interested.where(mission: whitelabel_mission).find(params[:id])
    end
end
