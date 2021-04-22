class Blockchain::Ethereum < Blockchain
  # Generated template for implementing a new blockchain subclass
  # See: rails g blockchain -h

  # Name of the blockchain for UI purposes
  # @return [String] name
  def name
    'Ethereum'
  end

  # Hostname of block explorer API
  # @return [String] hostname
  def explorer_api_host
    'mainnet.infura.io'
  end

  # Hostname of block explorer website
  # @return [String] hostname
  def explorer_human_host
    'etherscan.io'
  end

  # Is mainnet?
  # @return [Boolean] mainnet?
  def mainnet?
    true
  end

  # Number of confirmations to wait before marking transaction as successful
  # @return [Integer] number
  def number_of_confirmations
    3
  end

  # Seconds to wait between syncs with block explorer API
  # @return [Integer] seconds
  def sync_period
    60
  end

  # Maximum number of syncs with block explorer API
  # @return [Integer] number
  def sync_max
    10
  end

  # Seconds to wait when transaction is created
  # @return [Integer] seconds
  def sync_waiting
    600
  end

  # Transaction url on block explorer website
  # @return [String] url
  def url_for_tx_human(hash)
    "https://#{explorer_human_host}/tx/#{hash}"
  end

  # Transaction url on block explorer API
  # @return [String] url
  def url_for_tx_api(hash)
    "https://#{explorer_api_host}/tx/#{hash}"
  end

  # Address url on block explorer website
  # @return [String] url
  def url_for_address_human(addr)
    "https://#{explorer_human_host}/address/#{addr}"
  end

  # Address url on block explorer API
  # @return [String] url
  def url_for_address_api(addr)
    "https://#{explorer_api_host}/addr/#{addr}"
  end

  # Validate blockchain transaction hash
  # @raise [Blockchain::Tx::ValidationError]
  # @return [void]
  def validate_tx_hash(hash)
    raise Blockchain::Tx::ValidationError if hash.blank?
  end

  # Validate blockchain address
  # @raise [Blockchain::Address::ValidationError]
  # @return [void]
  def validate_addr(addr)
    validate_addr_format(addr)
  end

  def validate_addr_format(addr)
    raise Blockchain::Address::ValidationError, "should start with '0x', followed by 40 hex characters" unless /\A0x[0-9a-fA-F]{40}\z/.match?(addr)
  end

  # Is it supported by OreId service
  # @return [Boolean] flag
  def supported_by_ore_id?
    self.class.ore_id_configured? && true
  end

  # Name of the blockchain on OreId service, if supported
  # @return [String] name
  def ore_id_name
    'eth_main'
  end

  # Return current block
  # @return [Integer] current block
  def current_block
    Comakery::Eth.new(explorer_api_host).current_block
  end
end
