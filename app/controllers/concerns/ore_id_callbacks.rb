module OreIdCallbacks
  extend ActiveSupport::Concern

  private

    def current_ore_id_account
      @current_ore_id_account ||= (current_account.ore_id_account || current_account.create_ore_id_account(state: :pending_manual))
    end

    def auth_url
      @auth_url ||= current_ore_id_account.service.authorization_url(auth_ore_id_receive_url, state)
    end

    def sign_url
      @sign_url ||= current_ore_id_account.service.sign_url(
        account: current_ore_id_account.account_name,
        wallet_from: nil, # fix me
        callback_url: sign_ore_id_receive_url,
        ore_id_network: 'ore_test', # fill me dynamicly
        transaction_data: {}.to_json, # fill me
        broadcast: true,
        state: state
      )
    end

    def crypt
      @crypt ||= ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base[0..31])
    end

    def state
      @state ||= crypt.encrypt_and_sign({
        account_id: current_account.id,
        redirect_back_to: params[:redirect_back_to] || request.referer
      }.to_json)
    end

    def received_state
      @received_state ||= JSON.parse(crypt.decrypt_and_verify(params.require(:state)))
    end
end
