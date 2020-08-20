class TokenType::Ada < TokenType
  # Generated template for implementing a new token type subclass
  # See: rails g token_type -h

  # Name of the token type for UI purposes
  # @return [String] name
  def name
    'ADA'
  end

  # Symbol of the token type for UI purposes
  # @return [String] symbol
  def symbol
    'ADA'
  end

  # Number of decimals
  # @return [Integer] number
  def decimals
    0
  end

  # Contract class if implemented
  # @return [nil]
  def contract
    # Comakery::Eth::Contract::Erc20
  end

  # Transaction class if implemented
  # @return [nil]
  def tx
    # Comakery::Eth::Tx
  end
end
