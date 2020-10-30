class TokensController < ApplicationController
  before_action :redirect_unless_admin
  before_action :set_token, only: %i[show edit update]
  before_action :set_token_types, only: %i[new show edit]
  before_action :set_blockchains, only: %i[new show edit]
  before_action :set_generic_props, only: %i[new show edit]

  def index
    @tokens = policy_scope(Token).map do |t|
      t.serializable_hash.merge(
        logo_url: Refile.attachment_url(t, :logo_image, :fill, 54, 54)
      )
    end

    render component: 'TokenIndex', props: { tokens: @tokens }
  end

  def new
    @token = Token.create
    authorize @token

    @props[:token] = @token.serializable_hash
    render component: 'TokenForm', props: @props, prerender: false
  end

  def create
    @token = Token.create token_params
    authorize @token

    if @token.save
      render json: { id: @token.id }, status: :ok
    else
      errors  = @token.errors.messages.map { |k, v| ["token[#{k}]", v.to_sentence] }.to_h
      message = @token.errors.full_messages.join(', ')
      render json: { message: message, errors: errors }, status: :unprocessable_entity
    end
  end

  def show
    authorize @token

    @props[:form_action] = 'PATCH'
    @props[:form_url]    = token_path(@token)
    render component: 'TokenForm', props: @props
  end

  def edit
    authorize @token

    @props[:form_action] = 'PATCH'
    @props[:form_url]    = token_path(@token)
    render component: 'TokenForm', props: @props
  end

  def update
    authorize @token

    if @token.update token_params
      render json: { message: 'Token updated' }, status: :ok
    else
      errors  = @token.errors.messages.map { |k, v| [k, v.to_sentence] }.to_s
      message = @token.errors.full_messages.join(', ')
      render json: { message: message, errors: errors }, status: :unprocessable_entity
    end
  end

  def fetch_contract_details
    authorize Token.create

    host = Token.blockchain_for(params[:network]).explorer_api_host

    case params[:address]
    when /^0x[a-fA-F0-9]{40}$/
      web3 = Comakery::Web3.new(host)
      @symbol, @decimals = web3.fetch_symbol_and_decimals(params[:address])
    when /^[a-fA-F0-9]{40}$/
      qtum = Comakery::Qtum.new(host)
      @symbol, @decimals = qtum.fetch_symbol_and_decimals(params[:address])
    end

    render json: { symbol: @symbol, decimals: @decimals }, status: :ok
  end

  private

    def redirect_unless_admin
      redirect_to root_path unless current_account.comakery_admin?
    end

    def set_token
      @token = Token.find(params[:id]).decorate
    end

    def set_token_types
      @token_types = Token._token_types.keys.map { |k| [k, k] }.to_h
    end

    def set_blockchains
      available_blockchains =
        if Token.testnets_available?
          Blockchain.all
        else
          Blockchain.without_testnets
        end
      @blockchains = available_blockchains.map { |k| [k.key, k.key] }.to_h
    end

    def set_generic_props # rubocop:todo Metrics/CyclomaticComplexity
      @props = {
        token: @token&.serializable_hash&.merge(
          {
            logo_url: @token&.logo_image&.present? ? Refile.attachment_url(@token, :logo_image, :fill, 500, 500) : nil
          }
        ),
        token_types: @token_types,
        blockchains: @blockchains,
        form_url: tokens_path,
        form_action: 'POST',
        url_on_success: tokens_path,
        csrf_token: form_authenticity_token
      }
    end

    def token_params
      params.require(:token).permit(
        :name,
        :logo_image,
        :denomination,
        :_token_type,
        :_blockchain,
        :contract_address,
        :symbol,
        :decimal_places,
        :unlisted
      )
    end
end
