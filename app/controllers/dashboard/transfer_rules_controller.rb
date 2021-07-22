class Dashboard::TransferRulesController < ApplicationController
  before_action :assign_project
  before_action :set_reg_groups, only: [:index]
  before_action :set_transfer_rules, only: [:index]
  before_action :set_transfer_rule, only: [:destroy]
  skip_before_action :require_login, only: [:index]
  skip_after_action :verify_policy_scoped, only: [:index]

  fragment_cache_key do
    "#{current_user&.id}/#{@project.id}/#{@project.token&.updated_at}"
  end

  def index
    authorize @project, :show_transfer_rules?
  end

  def create
    authorize @project, :edit_transfer_rules?

    transfer_rule = @project.token.transfer_rules.new(transfer_rule_params)
    transfer_rule.lockup_until = Time.zone.parse(transfer_rule_params[:lockup_until])

    if transfer_rule.save
      case request.headers['X-Sign-Controller']
      when 'metamask', 'wallet-connect'
        render json: {
          tx_new_url: sign_user_wallet_new_path(transfer_rule_id: transfer_rule.id),
          tx_receive_url: sign_user_wallet_receive_path
        }
      when 'ore-id'
        redirect_to sign_ore_id_new_path(transfer_rule_id: transfer_rule.id)
      end
    else
      redirect_to project_dashboard_transfer_rules_path(@project), flash: { error: transfer_rule.errors.full_messages.join(', ') }
    end
  end

  def destroy
    authorize @project, :edit_transfer_rules?
    transfer_rule = @transfer_rule.dup
    transfer_rule.lockup_until = 0
    transfer_rule.status = nil
    transfer_rule.save!

    case request.headers['X-Sign-Controller']
    when 'metamask', 'wallet-connect'
      render json: {
        tx_new_url: sign_user_wallet_new_path(transfer_rule_id: transfer_rule.id),
        tx_receive_url: sign_user_wallet_receive_path
      }
    when 'ore-id'
      redirect_to sign_ore_id_new_path(transfer_rule_id: transfer_rule.id)
    end
  end

  def freeze
    authorize @project, :freeze_token?
    redirect_to sign_ore_id_new_path(token_id: @project.token.id)
  end

  def refresh_from_blockchain
    authorize @project, :refresh_transfer_rules?

    if @project.token.transfer_rules.fresh?
      notice = 'Transfer rules were already synced'
    else
      @project.token.transfer_rules.outdate_all
      @project.token.token_type.transfer_rule_sync_job&.perform_now(@project.token)
      notice = 'Transfer rules were synced from the blockchain'
    end

    redirect_to project_dashboard_transfer_rules_path(@project), notice: notice
  end

  private

    def set_reg_groups
      @reg_groups = @project.token.reg_groups.order(:blockchain_id)
    end

    def set_transfer_rules
      @page = (params[:page] || 1).to_i
      @q = @project.token.transfer_rules.not_outdated.ransack(params[:q])
      @transfer_rules_all = @q.result.includes(:sending_group, :receiving_group)
      @transfer_rules = @transfer_rules_all.page(@page).per(10)
      redirect_to '/404.html' if (@page > 1) && @transfer_rules.out_of_range?
    end

    def set_transfer_rule
      @transfer_rule = @project.token.transfer_rules.not_outdated.find(params[:id])
    end

    def transfer_rule_params
      params.fetch(:transfer_rule, {}).permit(
        :sending_group_id,
        :receiving_group_id,
        :lockup_until
      )
    end
end
