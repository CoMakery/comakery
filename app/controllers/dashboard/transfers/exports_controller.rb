# frozen_string_literal: true

module Dashboard
  module Transfers
    class ExportsController < ApplicationController
      before_action :assign_project

      def create
        authorize @project, :export_transfers?

        ProjectExportTransfersJob.perform_later(@project.id, current_account.id)

        redirect_to project_dashboard_transfers_path(@project), notice: "CSV will be sent to #{current_account.email}"
      end
    end
  end
end
