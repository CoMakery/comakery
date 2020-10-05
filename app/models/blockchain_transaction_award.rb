class BlockchainTransactionAward < BlockchainTransaction
  validates :destination, presence: true

  def update_transactable_status
    blockchain_transactable.update!(status: :paid)
  end

  def on_chain
    @on_chain ||= if token._token_type_on_ethereum?
      on_chain_eth
    elsif token._token_type_dag?
      on_chain_dag
    end
  end

  private

    def on_chain_eth
      if token._token_type_token?
        case blockchain_transactable.transfer_type.name
        when 'mint'
          Comakery::Eth::Tx::Erc20::Mint.new(token.blockchain.explorer_api_host, tx_hash)
        when 'burn'
          Comakery::Eth::Tx::Erc20::Burn.new(token.blockchain.explorer_api_host, tx_hash)
        else
          Comakery::Eth::Tx::Erc20::Transfer.new(token.blockchain.explorer_api_host, tx_hash)
        end
      else
        Comakery::Eth::Tx.new(token.blockchain.explorer_api_host, tx_hash)
      end
    end

    def on_chain_dag
      Comakery::Dag::Tx.new(token.blockchain.explorer_api_host, tx_hash)
    end

    def populate_data
      super
      self.amount ||= token.to_base_unit(blockchain_transactable.total_amount)
      self.destination ||= blockchain_transactable.recipient_address
    end

    def tx
      @tx ||= destination && case blockchain_transactable.source
                             when 'mint'
                               contract.mint(destination, amount)
                             when 'burn'
                               contract.burn(destination, amount)
                             else
                               contract.transfer(destination, amount)
                             end
    end
end
