class TokensController < ApplicationController
  TOKENS_PER_PAGE = 10

  before_action :redirect_unless_admin
  before_action :set_token, only: %i[show edit update]
  before_action :set_token_types, only: %i[new show edit]
  before_action :set_blockchains, only: %i[new show edit]
  before_action :set_generic_props, only: %i[new show edit]

  def index
    @props = {
      tokens: serialized_tokens,
      pagination_html: helpers.paginate(tokens, window: 3)
    }
  end

  def new
    @token = Token.create
    authorize @token

    @props[:token] = @token.serializable_hash
  end

  def create
    @token = Token.create token_params
    authorize @token

    if ImagePixelValidator.new(@token, token_params).valid? && @token.save
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
  end

  def edit
    authorize @token

    @props[:form_action] = 'PATCH'
    @props[:form_url]    = token_path(@token)
  end

  def update
    authorize @token

    if ImagePixelValidator.new(@token, token_params).valid? && @token.update(token_params)
      render json: { message: 'Token updated' }, status: :ok
    else
      errors  = @token.errors.messages.map { |k, v| [k, v.to_sentence] }.to_s
      message = @token.errors.full_messages.join(', ')
      render json: { message: message, errors: errors }, status: :unprocessable_entity
    end
  end

  def fetch_contract_details
    authorize Token.create

    token_type = build_token_type(params.require(:token_type), params.require(:network), params.require(:address))
    @symbol = token_type.symbol
    @decimals = token_type.decimals

    render json: { symbol: @symbol, decimals: @decimals }, status: :ok
  rescue TokenType::Contract::ValidationError
    render json: { error: 'Contract address is invalid' }, status: :bad_request
  end

  private

    def tokens
      @tokens ||=
        policy_scope(Token)
        .with_attached_logo_image
        .page(params[:page])
        .per(TOKENS_PER_PAGE)
    end

    def serialized_tokens
      tokens.map do |t|
        t.serializable_hash.merge(
          logo_url: GetImageVariantPath.call(
            attachment: t.logo_image,
            resize_to_fill: [54, 54]
          ).path
        )
      end
    end

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
      available_blockchains = Blockchain.available
      @blockchains = available_blockchains.map { |k| [k.key, k.key] }.to_h
    end

    def set_generic_props
      @props = {
        token: @token&.serializable_hash&.merge(
          {
            logo_url: GetImageVariantPath.call(attachment: @token&.logo_image, resize_to_fill: [500, 500]).path
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
        :batch_contract_address,
        :symbol,
        :decimal_places,
        :unlisted
      )
    end

    def build_token_type(token_type, blockchain, contract_address)
      "TokenType::#{token_type.to_s.camelize}".constantize.new(
        blockchain: "Blockchain::#{blockchain.to_s.camelize}".constantize.new,
        contract_address: contract_address
      )
    end
end
