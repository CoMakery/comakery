# frozen_string_literal: true

module Dashboard
  module Transfers
    class PrioritizesController < ApplicationController
      before_action :assign_project

      def update
        authorize @project, :update_transfer?

        @transfer = @project.awards.find(params[:transfer_id])

        @transfer.update(prioritized_at: Time.zone.now)

        redirect_to project_dashboard_transfers_path(@project), flash: { notice: 'Transfer will be sent soon' }
      end
    end
  end
end
