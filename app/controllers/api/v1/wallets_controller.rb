class Api::V1::WalletsController < Api::V1::ApiController
  include Api::V1::Concerns::AuthorizableByMissionKey
  include Api::V1::Concerns::RequiresAnAuthorization
  include Api::V1::Concerns::RequiresSignature
  include Api::V1::Concerns::RequiresWhitelabelMission

  # GET /api/v1/accounts/1/wallets
  def index
    fresh_when wallets, public: true
  end

  # POST /api/v1/wallets
  def create
    wallet = account.wallets.new(wallet_params)

    Wallet.transaction do
      @wallet_created = wallet.save
      create_wallet_provisions(wallet) if @wallet_created
    end

    if @wallet_created
      @wallet = wallet
      render 'show.json', status: :created
    else
      @errors = wallet.errors

      render 'api/v1/error.json', status: :bad_request
    end
  end

  # GET /api/v1/accounts/1/wallets/1
  def show
    fresh_when wallet, public: true
  end

  # DELETE /api/v1/accounts/1/wallets/1
  def destroy
    wallet.destroy

    if wallet.persisted?
      @errors = wallet.errors

      render 'api/v1/error.json', status: :bad_request
    else
      wallets

      render 'index.json', status: :ok
    end
  end

  # POST /api/v1/accounts/1/wallets/1/password_reset
  def password_reset
    @auth_url = wallet.ore_id_account.service.authorization_url(redirect_url, params.dig(:proof, :signature))
    wallet.ore_id_account.schedule_password_update_sync

    render 'password_reset.json', status: :ok
  end

  private

    def account
      @account ||= whitelabel_mission.managed_accounts.find_by!(managed_account_id: params[:account_id])
    end

    def wallets
      @wallets ||= paginate(account.wallets)
    end

    def wallet
      @wallet ||= account.wallets.find(params[:id])
    end

    def wallet_params
      r = params.fetch(:body, {}).fetch(:data, {}).fetch(:wallet, {}).permit(
        :blockchain,
        :address,
        :source
      )

      r[:_blockchain] = r[:blockchain]
      r.delete(:blockchain)
      r
    end

    def redirect_url
      @redirect_url ||= params.fetch(:body, {}).fetch(:data, {}).fetch(:redirect_url, nil)
    end

    def tokens_to_provision
      params.dig(:body, :data, :wallet, :tokens_to_provision) || []
    end

    def create_wallet_provisions(wallet)
      return if tokens_to_provision.empty?

      tokens_to_provision.each do |token_to_provision|
        wallet.wallet_provisions.create!(token_id: token_to_provision)
      end
    end
end
