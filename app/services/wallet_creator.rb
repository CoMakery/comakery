class WalletCreator
  class WrongTokensFormat < StandardError; end

  AVAILABLE_PARAMS = %i[token_id max_balance lockup_until reg_group_id account_id account_frozen].freeze

  attr_reader :account, :errors

  def initialize(account:)
    @account = account
  end

  def call(wallets_params)
    errors = {}
    wallets = wallets_params.map.with_index do |wallet_attrs, i|
      tokens_to_provision = wallet_attrs.delete(:tokens_to_provision)
      wallet_attrs[:_blockchain] = wallet_attrs.delete(:blockchain)

      wallet = account.wallets.new(wallet_attrs)

      provision = Provision.new(wallet, tokens_to_provision)

      if provision.should_be_provisioned?
        build_wallet_provisions(provision)
        build_account_token_records(provision)
      end

      errors[i] = provision.wallet.errors if provision.wallet.errors.any?

      provision.wallet
    end

    account.save if errors.empty?
    [wallets, errors]
  end

  private

    # def tokens_to_provision_params(tokens_to_provision)
    #   return unless tokens_to_provision
    #   return unless tokens_to_provision.is_a?(Array)
    #   return unless tokens_to_provision.first.is_a?(ActionController::Parameters)

    #   tokens_to_provision
    # end

    # def valid_tokens_to_provision?(wallet, provision_params)
    #   correct_tokens = Token.available_for_provision.where(id: provision_params.map{ |p| p[:token_id] }
    #   wrong_tokens = provision_params.map { |t| t.fetch(:token_id, nil) }.compact.map(&:to_i) - correct_tokens.pluck(:id)

    #   if wrong_tokens.any?
    #     wallet.errors.add(:tokens_to_provision, "Some tokens can't be provisioned: #{wrong_tokens}")
    #     return false
    #   end

    #   true
    # end

    def build_wallet_provisions(provision)
      provision.params.each do |provision_params|
        token_id = provision_params.fetch(:token_id)
        provision.wallet.wallet_provisions.new(token_id: token_id)
      end
    end

    def build_account_token_records(provision)
      provision.params.filter do |params|
        token = Token.available_for_provision.find_by(id: params[:token_id])
        next if token.nil? || !token.token_type.operates_with_account_records?

        provision.wallet.account.account_token_records.new(params)
      end
    end
end

class WalletCreator::Provision
  attr_reader :wallet, :params

  def initialize(wallet, params)
    @wallet = wallet
    @params = sanitize_params(params)
  end

  def should_be_provisioned?
    params && wallet.valid? && valid?
  end

  def valid?
    unavailable_token_ids = params.map { |t| t.fetch(:token_id) }.map(&:to_i) - available_tokens_to_provision.pluck(:id)

    if unavailable_token_ids.any?
      wallet.errors.add(:tokens_to_provision, "Some tokens can't be provisioned: #{unavailable_token_ids}")
      return false
    end

    true
  end

  private

    def available_tokens_to_provision
      @available_tokens_to_provision ||= Token.available_for_provision.where(id: params.map{ |p| p[:token_id] })
    end

    def sanitize_params(params)
      return [] unless params.is_a?(Array)
      return [] unless params.first.is_a?(ActionController::Parameters)

      params
    end
end
