class BlockchainTransactionAward < BlockchainTransaction
  validates :destination, presence: true
  after_update :broadcast_updates

  def update_transactable_status
    blockchain_transactable.update!(status: :paid)
  end

  # TODO: Refactor on_chain condition into TokenType
  def on_chain # rubocop:todo Metrics/CyclomaticComplexity
    @on_chain ||= if token._token_type_on_ethereum?
      on_chain_eth
    elsif token._token_type_dag?
      on_chain_dag
    elsif token._token_type_algo?
      on_chain_algo
    elsif token._token_type_asa?
      on_chain_asa
    elsif token._token_type_algorand_security_token?
      on_chain_ast
    end
  end

  def broadcast_updates
    broadcast_replace_later_to(
      blockchain_transactable,
      :updates,
      target: "transfer_history_button_#{blockchain_transactable.id}",
      partial: 'dashboard/transfers/transfer_history_button',
      locals: { transfer: blockchain_transactable }
    )

    broadcast_replace_later_to(
      blockchain_transactable,
      :updates,
      target: "transfer_button_public_#{blockchain_transactable.id}",
      partial: 'shared/transfer_button_public',
      locals: { transfer: blockchain_transactable }
    )

    broadcast_replace_later_to(
      blockchain_transactable,
      :updates,
      target: "transfer_button_admin_#{blockchain_transactable.id}",
      partial: 'shared/transfer_button_admin',
      locals: { transfer: blockchain_transactable }
    )
  end

  private

    def on_chain_eth
      if token._token_type_token?
        case blockchain_transactable.transfer_type.name
        when 'mint'
          Comakery::Eth::Tx::Erc20::Mint.new(token.blockchain.explorer_api_host, tx_hash, self)
        when 'burn'
          Comakery::Eth::Tx::Erc20::Burn.new(token.blockchain.explorer_api_host, tx_hash, self)
        else
          Comakery::Eth::Tx::Erc20::Transfer.new(token.blockchain.explorer_api_host, tx_hash, self)
        end
      else
        Comakery::Eth::Tx.new(token.blockchain.explorer_api_host, tx_hash, self)
      end
    end

    def on_chain_dag
      Comakery::Dag::Tx.new(token.blockchain.explorer_api_host, tx_hash)
    end

    def on_chain_algo
      Comakery::Algorand::Tx.new(self)
    end

    def on_chain_asa
      Comakery::Algorand::Tx::Asset.new(self)
    end

    def on_chain_ast
      case blockchain_transactable.transfer_type.name
      when 'mint'
        on_chain_ast_mint
      when 'burn'
        on_chain_ast_burn
      else
        on_chain_ast_transfer
      end
    end

    def on_chain_ast_transfer
      Comakery::Algorand::Tx::App::SecurityToken::Transfer.new(self)
    end

    def on_chain_ast_burn
      Comakery::Algorand::Tx::App::SecurityToken::Burn.new(self)
    end

    def on_chain_ast_mint
      Comakery::Algorand::Tx::App::SecurityToken::Mint.new(self)
    end

    def populate_data
      super
      self.amount ||= token.to_base_unit(blockchain_transactable.total_amount)
      self.destination ||= blockchain_transactable.recipient_address
    end
end
