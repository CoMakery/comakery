class Api::V1::InterestsController < Api::V1::ApiController
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

      render 'index.json', status: :created
    else
      @errors = interest.errors

      render 'api/v1/error.json', status: :bad_request
    end
  end

  # DELETE /api/v1/accounts/1/interests/1
  def destroy
    interest.interests.find_by!(account: account).destroy
    interests

    render 'index.json', status: :ok
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
