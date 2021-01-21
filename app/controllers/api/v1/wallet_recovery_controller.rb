class Api::V1::WalletRecoveryController < Api::V1::ApiController
  # TODO: Which authorization use here?

  def public_wrapping_key
    public_key = Eth::Key.new(priv: ENV['WALLET_RECOVERY_WRAPPING_KEY']).public_key.key

    render json: { public_wrapping_key: public_key }
  rescue MoneyTree::Key::KeyFormatNotFound
    @errors = { invalid_env_variable: 'WALLET_RECOVERY_WRAPPING_KEY variable was not configured or use wrong format' }
    render 'api/v1/error.json', status: :internal_server_error
  end
end
