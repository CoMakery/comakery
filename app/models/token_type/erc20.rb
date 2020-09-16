class TokenType::Erc20 < TokenType
  # Generated template for implementing a new token type subclass
  # See: rails g token_type -h

  # Name of the token type for UI purposes
  # @return [String] name
  def name
    'ERC20'
  end

  # Symbol of the token type for UI purposes
  # @return [String] symbol
  def symbol
    @symbol ||= contract.symbol.to_s
  end

  # Number of decimals
  # @return [Integer] number
  def decimals
    @decimals ||= contract.decimals.to_i
  end

  # Contract instance if implemented
  # @return [nil]
  def contract
    @contract ||= Comakery::Eth::Contract::Erc20.new(contract_address, abi, blockchain.explorer_api_host, nil)
  end

  # ABI structure if present
  # @return [Hash] abi
  def abi
    # rubocop:todo Rails/FilePath
    @abi ||= JSON.parse(File.read(Rails.root.join('vendor', 'abi', 'coin_types', 'default.json')))
    # rubocop:enable Rails/FilePath
  end

  # Transaction instance if implemented
  # @return [nil]
  def tx
    # Comakery::Eth::Tx.new::Erc20
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
end
