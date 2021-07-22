# frozen_string_literal: true

module Dashboard
  class TransfersController < ApplicationController
    skip_before_action :require_login, only: %i[index show]
    skip_after_action :verify_policy_scoped, only: %i[index show]

    before_action :assign_project

    fragment_cache_key { "#{current_user&.id}/#{@project.id}/#{@project.token&.updated_at}" }

    def index
      authorize @project, :transfers?

      @transfers_chart_colors_objects = @project.transfers_chart_colors_objects

      @q = SearchTransfersQuery.new(
        @project.awards.completed_or_cancelled,
        params
      ).call

      begin
        @unfiltered_transfers = @q.result(distinct: true).reorder('')
      rescue ActiveRecord::StatementInvalid
        head :not_found
      end

      @transfers = ReorderTransfersQuery.new(
        @unfiltered_transfers,
        params
      ).call

      @transfers = @transfers.page(page).per(10)

      flash[:notice] = "Displaying first page of filtered results. Not enough results to display page #{page}." if page > 1 && @transfers.out_of_range?
    end

    def new
      authorize @project, :create_transfer?

      @transfer = Award.new(transfer_params)
    end

    def update
      authorize @project, :update_transfer?

      @transfer = @project.awards.find(params[:id])

      result = ::Transfers::Update.call(transfer: @transfer, transfer_params: transfer_params)

      if result.success?
        redirect_to project_dashboard_transfers_path(@project), notice: 'Transfer Updated'
      else
        redirect_to project_dashboard_transfers_path(@project), flash: { error: result.error }
      end
    end

    def create
      authorize @project, :create_transfer?

      result = ::Transfers::Create.call(
        issuer: current_account,
        account_id: params[:award][:account_id],
        award_type: @project.default_award_type,
        transfer_params: transfer_params
      )

      if result.success?
        redirect_to project_dashboard_transfers_path(@project), flash: { notice: 'Transfer Created' }
      else
        redirect_to project_dashboard_transfers_path(@project), flash: { error: result.error }
      end
    end

    def edit
      authorize @project, :update_transfer?

      @transfer = @project.awards.find(params[:id])
    end

    def show
      authorize @project, :transfers?

      @transfer = @project.awards.find(params[:id])
    end

    private

      def transfer_params
        params.fetch(:award, {}).permit(
          :amount,
          :quantity,
          :price,
          :why,
          :description,
          :requirements,
          :recipient_wallet_id,
          :transfer_type_id,
          :lockup_schedule_id,
          :commencement_date
        )
      end

      def page
        @page ||= params.fetch(:page, 1).to_i
      end
  end
end
