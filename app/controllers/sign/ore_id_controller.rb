class Sign::OreIdController < ApplicationController
  include OreIdCallbacks
  skip_after_action :verify_authorized, only: :receive, unless: :verify_errorless
  skip_after_action :verify_authorized, only: :new, unless: :new_transaction_for_award?

  # POST /sign/ore_id/new
  def new
    # TODO: Add token admin role to policy token related tx
    authorize new_transaction.blockchain_transactable, :pay? if new_transaction.is_a?(BlockchainTransactionAward)

    new_transaction.source = current_account.address_for_blockchain(new_transaction.blockchain_transactable._blockchain)
    new_transaction.save!

    redirect_to sign_url(new_transaction)
  end

  # GET /sign/ore_id/receive
  def receive
    fallback_state

    unless verify_errorless
      fallback_transaction.update_status(:cancelled, received_error&.truncate(100))
      redirect_to fallback_state['redirect_back_to'] || wallets_url
      return
    end

    unless verify_received_account
      head 401
      return
    end

    authorize received_transaction.blockchain_transactable, :pay?

    if received_transaction.update(tx_hash: params.require(:transaction_id), tx_raw: Base64.decode64(params.require(:signed_transaction)))
      received_transaction.update_status(:pending)
      BlockchainJob::BlockchainTransactionSyncJob.perform_later(received_transaction)
      flash[:notice] = 'Transaction Signed'
    else
      flash[:error] = received_transaction.errors.full_messages.join(', ')
    end

    redirect_to received_state['redirect_back_to']
  end

  private

    def new_transaction
      @new_transaction ||= if params[:transfer_id]
        BlockchainTransactionAward.new(
          blockchain_transactable: policy_scope(Award).find(params.require(:transfer_id))
        )
      elsif params[:account_token_record_id]
        BlockchainTransactionAccountTokenRecord.new(
          blockchain_transactable: AccountTokenRecord.find(params.require(:account_token_record_id))
        )
      elsif params[:token_id]
        BlockchainTransactionAccountTokenRecord.new(
          blockchain_transactable: Token.find(params.require(:token_id))
        )
      end
    end

    def new_transaction_for_award?
      new_transaction.is_a?(BlockchainTransactionAward)
    end

    def received_transaction
      @received_transaction ||= BlockchainTransaction.find(received_state['transaction_id'])
    end

    def fallback_transaction
      @fallback_transaction ||= BlockchainTransaction.find(fallback_state['transaction_id'])
    end
end
