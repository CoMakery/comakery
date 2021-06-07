class TokenType::Asa < TokenType
  # Generated template for implementing a new token type subclass
  # See: rails g token_type -h

  # Name of the token type for UI purposes
  # @return [String] name
  def name
    'ASA'
  end

  # Symbol of the token type for UI purposes
  # @return [String] symbol
  def symbol
    @symbol ||= contract&.symbol&.to_s
  end

  # Number of decimals
  # @return [Integer] number
  def decimals
    @decimals ||= contract&.decimals&.to_i
  end

  # Wallet logo filename for UI purposes (relative to `app/assets/images`)
  # @return [String] filename
  def wallet_logo
    'OREID_Logo_Symbol.svg'
  end

  # Contract instance if implemented
  # @return [nil]
  def contract
    @contract ||=
      begin
        blockchain.validate_asset(contract_address)
        contract = Comakery::Algorand.new(blockchain, contract_address)
        @contract = contract
      end
  rescue Blockchain::Address::ValidationError, NoMethodError
    raise TokenType::Contract::ValidationError, 'is invalid'
  end

  # ABI structure if present
  # @return [Hash] abi
  def abi
    {}
  end

  # Transaction instance if implemented
  # @return [nil]
  def tx
    # Comakery::Eth::Tx.new.new
  end

  # Does it have support for smart contracts?
  # @return [Boolean] flag
  def operates_with_smart_contracts?
    true
  end

  # Does it have custom account data stored on chain?
  # @return [Boolean] flag
  def operates_with_account_records?
    false
  end

  # Does it have support for account groups?
  # @return [Boolean] flag
  def operates_with_reg_groups?
    false
  end

  # Does it have support for transfer restrictions between accounts/groups?
  # @return [Boolean] flag
  def operates_with_transfer_rules?
    false
  end

  # Does it have support for minting new tokens to a custom address?
  # @return [Boolean] flag
  def supports_token_mint?
    false
  end

  # Does it have support for burning existing tokens from a custom address?
  # @return [Boolean] flag
  def supports_token_burn?
    false
  end

  # Does it have support for temporal freezing of all token transactions?
  # @return [Boolean] flag
  def supports_token_freeze?
    false
  end

  def contract_address
    attrs[:contract_address]
  end

  def blockchain
    attrs[:blockchain]
  end

  # Does it have support for fetching balance?
  # @return [Boolean] flag
  def supports_balance?
    true
  end

  # Return balance of symbol for provided addr
  # @return [Integer] balance
  def blockchain_balance(wallet_address)
    contract.asset_balance(wallet_address)
  end

  # Token address url on block explorer website or just a link to block explorer
  # @return [String] url
  def human_url
    "https://#{blockchain.explorer_human_host}/asset/#{contract_address}"
  end

  # Link name for human_url
  # @return [String] url
  def human_url_name
    contract_address
  end
end
