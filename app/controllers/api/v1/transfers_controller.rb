class Api::V1::TransfersController < Api::V1::ApiController
  before_action :verify_decimal_params_precision, only: :create
  before_action :verify_total_amount, only: :create

  # GET /api/v1/projects/1/transfers
  def index
    fresh_when transfers, public: true
  end

  # GET /api/v1/projects/1/transfers/1
  def show
    fresh_when transfer, public: true
  end

  # POST /api/v1/projects/1/transfers
  def create
    award = project.default_award_type.awards.create(transfer_params)

    award.name = award.source.capitalize
    award.issuer = project.account
    award.account = whitelabel_mission.managed_accounts.find_by!(managed_account_id: params[:transfer][:account_id])
    award.status = :accepted

    award.why = '—'
    award.requirements = '—'
    award.description ||= '—'

    if award.save
      redirect_to api_v1_project_transfer_path(project, award)
    else
      @errors = award.errors

      render 'api/v1/error.json', status: 400
    end
  end

  # DELETE /api/v1/accounts/1/follows/1
  def destroy
    if transfer.update(status: :cancelled)
      redirect_to api_v1_project_transfer_path(project, transfer)
    else
      @errors = transfer.errors

      render 'api/v1/error.json', status: 400
    end
  end

  private

    def project
      @project ||= project_scope.find(params[:project_id])
    end

    def transfers
      @transfers ||= paginate(project.awards.completed_or_cancelled.includes(:account))
    end

    def transfer
      @transfer ||= project.awards.completed_or_cancelled.find(params[:id])
    end

    def transfer_params
      params.fetch(:transfer, {}).permit(
        :amount,
        :quantity,
        :total_amount,
        :source,
        :description
      )
    end

    def verify_decimal_params_precision
      a = Award.new

      if params[:transfer][:amount] != helpers.number_with_precision(params[:transfer][:amount], precision: project.token&.decimal_places.to_i)
        a.errors[:amount] << "has incorrect precision (should be #{project.token&.decimal_places.to_i})"
      end

      if params[:transfer][:total_amount] != helpers.number_with_precision(params[:transfer][:total_amount], precision: project.token&.decimal_places.to_i)
        a.errors[:total_amount] << "has incorrect precision (should be #{project.token&.decimal_places.to_i})"
      end

      if params[:transfer][:quantity] != helpers.number_with_precision(params[:transfer][:quantity], precision: Award::QUANTITY_PRECISION)
        a.errors[:quantity] << "has incorrect precision (should be #{Award::QUANTITY_PRECISION})"
      end

      unless a.errors.empty?
        @errors = a.errors

        return render 'api/v1/error.json', status: 400
      end
    end

    def verify_total_amount
      a = Award.new
      calculated_total_amount = (BigDecimal(params[:transfer][:amount] || 0) * BigDecimal(params[:transfer][:quantity] || 0)).to_s

      if params[:transfer][:total_amount] != helpers.number_with_precision(calculated_total_amount, precision: project.token&.decimal_places.to_i)
        a.errors[:total_amount] << "doesn't equal quantity times amount, possible multiplication error"
      end

      unless a.errors.empty?
        @errors = a.errors

        return render 'api/v1/error.json', status: 400
      end
    end
end
