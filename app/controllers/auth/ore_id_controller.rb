class Auth::OreIdController < ApplicationController
  include OreIdCallbacks
  skip_after_action :verify_authorized

  # GET /auth/ore_id/new
  def new
    redirect_to auth_url
  end

  # GET /auth/ore_id/receive
  def receive
    verify_errorless
    verify_received_account

    if current_ore_id_account.update(account_name: params.require(:account), state: :ok)
      flash[:notice] = 'Signed in with ORE ID'
    else
      flash[:error] = current_ore_id_account.errors.full_messages.join(', ')
    end

    redirect_to received_state['redirect_back_to']
  end
end
