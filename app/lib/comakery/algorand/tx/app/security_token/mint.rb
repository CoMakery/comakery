class Comakery::Algorand::Tx::App::SecurityToken::Mint < Comakery::Algorand::Tx::App
  def valid_app_accounts?(blockchain_transaction)
    transaction_app_accounts[0] == blockchain_transaction.destination
  end

  def valid_app_args?(blockchain_transaction)
    transaction_app_args[0] == 'mint' \
    && transaction_app_args[1] == blockchain_transaction.amount.to_s
  end
end
