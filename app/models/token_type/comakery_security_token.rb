class TokenType::ComakerySecurityToken < TokenType::Erc20
  # Generated template for implementing a new token type subclass
  # See: rails g token_type -h

  # Name of the token type for UI purposes
  # @return [String] name
  def name
    'Comakery Security Token'
  end

  # ABI structure if present
  # @return [Hash] abi
  def abi
    # rubocop:todo Rails/FilePath
    @abi ||= JSON.parse(File.read(Rails.root.join('vendor', 'abi', 'coin_types', 'comakery.json')))
    # rubocop:enable Rails/FilePath
  end

  # Does it have custom account data stored on chain?
  # @return [Boolean] flag
  def operates_with_account_records?
    true
  end

  # Does it have support for account groups?
  # @return [Boolean] flag
  def operates_with_reg_groups?
    true
  end

  # Does it have support for transfer restrictions between accounts/groups?
  # @return [Boolean] flag
  def operates_with_transfer_rules?
    true
  end

  # Does it have support for minting new tokens to a custom address?
  # @return [Boolean] flag
  def supports_token_mint?
    true
  end

  # Does it have support for burning existing tokens from a custom address?
  # @return [Boolean] flag
  def supports_token_burn?
    true
  end

  # Does it have support for temporal freezing of all token transactions?
  # @return [Boolean] flag
  def supports_token_freeze?
    true
  end

  # Default reg group when a record is created
  # @return [Integer] reg_group
  def default_reg_group
    0
  end

  # ApplicationJob class to perform transfer rule sync
  # @return [Class] job
  def transfer_rule_sync_job
    ::BlockchainJob::ComakerySecurityTokenJob::TransferRulesSyncJob
  end

  # ApplicationJob class to perform account sync
  # @return [Class] job
  def accounts_sync_job
    ::BlockchainJob::ComakerySecurityTokenJob::AccountTokenRecordsSyncJob
  end

  # Token address url on block explorer website or jast a link to block explorer
  # @return [String] url
  def human_url
    blockchain.url_for_address_human(contract_address)
  end

  # Link name for human_url
  # @return [String] url
  def human_url_name
    contract_address
  end
end
