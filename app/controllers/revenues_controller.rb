class RevenuesController < ApplicationController
  before_filter :assign_project #, only: :index
  # skip_before_filter :require_login #, only: :index

  def index
    @revenue = @project.revenues.new
  end

  def create
    authorize @project

    @revenue = @project.revenues.new(revenue_params)
    @revenue.currency = @project.denomination

    #TODO: test the invalid path, verify the denomination is properly set
    if @revenue.save
      redirect_to project_revenues_path(@project)
    else
      render template: 'revenues/index'
    end
  end

  private
  def assign_project
    @project = policy_scope(Project).find(params[:project_id]).decorate
  end

  def revenue_params
    params.require(:revenue).permit :amount,
                                    :comment,
                                    :transaction_reference,
                                    :project_id
  end
end