class PaymentsController < ApplicationController
  before_action :assign_project, :assign_current_account
  skip_before_action :require_login, only: :index

  def index
    @payment = @project.payments.new
  end

  def create
    payment_params = params.require(:payment).permit :quantity_redeemed

    @payment = @project.payments.new_with_quantity quantity_redeemed: payment_params[:quantity_redeemed], account: current_account
    @payment.truncate_total_value_to_currency_precision

    if @payment.save
      flash[:notice] = "#{@payment.decorate.total_value_pretty} pending payment by the project owner."
      redirect_to project_payments_path(@project)
    else
      render template: 'payments/index'
    end
  end

  def update
    update_params = params.require(:payment).permit :transaction_fee, :transaction_reference, :id
    @payment = Payment.find(params['id'])
    @payment.transaction_fee = update_params[:transaction_fee]
    @payment.transaction_reference = update_params[:transaction_reference]
    @payment.transaction_fee ||= 0
    @payment.total_payment = @payment.total_value - @payment.transaction_fee
    @payment.reconciled = true
    @payment.issuer = current_account

    flash[:error] = @payment.errors.full_messages.join(' ') unless @payment.save

    redirect_to project_payments_path(@project)
  end

  private

  def assign_project
    project = Project.find(params[:project_id])
    @project = project.decorate if project.share_revenue? && project.can_be_access?(current_account)
    redirect_to root_path unless @project
  end

  def assign_current_account
    @current_account_deco = current_account&.decorate
  end
end
