class Api::V1::BlockchainTransactionsController < Api::V1::ApiController
  skip_before_action :verify_signature
  skip_before_action :verify_public_key
  skip_before_action :allow_only_whitelabel
  before_action :verify_public_key_or_policy
  before_action :verify_hash, only: %i[update destroy]

  # POST /api/v1/projects/1/blockchain_transactions
  def create
    award = if transaction_create_params[:award_id]
      project.awards.find(transaction_create_params[:award_id])
    else
      project.awards.ready_for_blockchain_transaction.first
    end

    @transaction = award&.blockchain_transactions&.create(transaction_create_params)

    if @transaction&.persisted?
      render 'show.json', status: 201
    else
      @errors = { blockchain_transaction: 'No transfers available' }

      render 'api/v1/error.json', status: 204
    end
  end

  # PATCH/PUT /api/v1/projects/1/blockchain_transactions/1
  def update
    transaction.update_status(:pending)
    Blockchain::BlockchainTransactionSyncJob.perform_later(transaction)

    render 'show.json', status: 200
  end

  # DELETE /api/v1/projects/1/blockchain_transactions/1
  def destroy
    transaction.update_status(:cancelled, transaction_update_params[:status_message])

    render 'show.json', status: 200
  end

  private

    def project
      @project ||= project_scope.find(params[:project_id])
    end

    def transaction
      @transaction ||= project.blockchain_transactions.created.find(params[:id])
    end

    def transaction_create_params
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transaction, {}).permit(
        :source,
        :nonce,
        :award_id
      )
    end

    def transaction_update_params
      params.fetch(:body, {}).fetch(:data, {}).fetch(:transaction, {}).permit(
        :tx_hash,
        :status_message
      )
    end

    def verify_hash
      if transaction.tx_hash && transaction.tx_hash != transaction_update_params[:tx_hash]
        transaction.errors[:hash] << 'mismatch'
        @errors = transaction.errors

        render 'api/v1/error.json', status: 400
      end
    end
end
