class Api::V1::BlockchainTransactionsController < Api::V1::ApiController
  include Api::V1::Concerns::AuthorizableByMissionKey
  include Api::V1::Concerns::AuthorizableByProjectKey
  include Api::V1::Concerns::AuthorizableByProjectPolicy
  include Api::V1::Concerns::RequiresAnAuthorization

  # POST /api/v1/projects/1/blockchain_transactions
  def create
    return head :no_content if creation_disabled?

    if transactable
      @transaction = BlockchainTransaction.new(transaction_create_params)
      @transaction.create_batch([transactable].flatten)
      @transaction.save
    end

    if @transaction&.persisted?
      render 'show.json', status: :created
    else
      head :no_content
    end
  end

  # PATCH/PUT /api/v1/projects/1/blockchain_transactions/1
  def update
    if transaction.update(transaction_update_params)
      transaction.update_status(:pending)
      BlockchainJob::BlockchainTransactionSyncJob.perform_later(transaction)
    end

    render 'show.json', status: :ok
  end

  # DELETE /api/v1/projects/1/blockchain_transactions/1
  def destroy
    status = transaction_failed? ? :failed : :cancelled
    transaction.update_status(status, transaction_update_params[:status_message])

    render 'show.json', status: :ok
  end

  private

    def project
      @project ||= project_scope.find(params[:project_id])
    end

    def transaction
      @transaction ||= project.blockchain_transactions.find(params[:id])
    end

    def transactable_type
      @transactable_type ||= %w[
        account_token_records
        transfer_rules
        awards
      ].find do |type|
        type == params.dig(:body, :data, :blockchain_transactable_type)
      end
    end

    def transactable_id
      @transactable_id ||= params.dig(:body, :data, :blockchain_transactable_id)
    end

    def transactable
      @transactable ||= if transactable_type
        custom_transactable
      else
        default_transactable
      end
    end

    def custom_transactable
      collection = project.send(transactable_type)

      if transactable_id
        collection.ready_for_manual_blockchain_transaction.find(transactable_id)
      else
        collection.ready_for_blockchain_transaction.first
      end
    end

    def default_next_award_blockchain_transactable
      default_next_award_blockchain_transactable_hw_manual \
      || default_next_award_blockchain_transactable_batch \
      || default_next_award_blockchain_transactable_single
    end

    def default_next_award_blockchain_transactable_hw_manual
      project.awards.ready_for_hw_manual_blockchain_transaction.first if project.hot_wallet_manual_sending? && hot_wallet_request?
    end

    def default_next_award_blockchain_transactable_batch
      batch_size = ENV['ERC20_TRANSFER_BATCH_SIZE'].to_i

      project.awards.ready_for_batch_blockchain_transaction.first(batch_size) if batch_size > 1 && project.awards.ready_for_batch_blockchain_transaction.any?
    end

    def default_next_award_blockchain_transactable_single
      project.awards.ready_for_blockchain_transaction.first
    end

    def default_next_account_token_record_blockchain_transactable
      if project.hot_wallet_manual_sending? && hot_wallet_request?
        project.account_token_records.ready_for_hw_manual_blockchain_transaction.first
      else
        project.account_token_records.ready_for_blockchain_transaction.first
      end
    end

    def default_transactable
      default_next_account_token_record_blockchain_transactable || default_next_award_blockchain_transactable
    end

    def transaction_create_params
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transaction, {}).permit(
        :source,
        :nonce
      )
    end

    def transaction_update_params
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transaction, {}).permit(
        :tx_hash,
        :status_message
      )
    end

    def transaction_failed?
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transaction, {}).permit(
        :failed
      ).present?
    end

    def hot_wallet_request?
      @hot_wallet_request ||= project.hot_wallet&.address == transaction_create_params[:source]
    end

    def hot_wallet_disabled?
      project.hot_wallet_disabled? && hot_wallet_request?
    end

    def creation_disabled?
      hot_wallet_disabled? || project.token.token_frozen?
    end
end
