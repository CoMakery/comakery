module OreIdCallbacks
  extend ActiveSupport::Concern

  ERROR_MESSAGE_SIZE_LIMIT = 1_000

  def current_ore_id_account
    @current_ore_id_account ||= (current_account.ore_id_account || current_account.create_ore_id_account(state: :pending_manual))
  end

  def auth_url
    @auth_url ||= current_ore_id_account.service.authorization_url(auth_ore_id_receive_url, state)
  end

  def sign_url(transaction)
    @sign_url ||= current_ore_id_account.service.sign_url(
      transaction: transaction,
      callback_url: sign_ore_id_receive_url,
      state: state(transaction_id: transaction.id)
    )
  end

  def crypt
    @crypt ||= ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
  end

  def state(**additional_params)
    @state ||= crypt.encrypt_and_sign({
      account_id: current_account.id,
      redirect_back_to: params[:redirect_back_to] || request.referer
    }.merge(additional_params).to_json)
  end

  def received_state
    @received_state ||= JSON.parse(crypt.decrypt_and_verify(params.require(:state)))
  end

  def received_error
    @received_error ||= params[:error_message] || params[:error_code]
  end

  def verify_errorless
    if received_error
      flash[:error] = received_error.truncate(ERROR_MESSAGE_SIZE_LIMIT) # Error Message can exceed the 4KB limit for cookies
      false
    else
      true
    end
  end

  def verify_received_account
    current_account.id == received_state['account_id']
  end
end
