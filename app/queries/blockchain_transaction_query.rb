class BlockchainTransactionQuery
  attr_reader :project, :transactable_classes, :target, :options

  def initialize(project:, transactable_classes:, target:, include_failed: false, verified_accounts_only: true, batch: false)
    @project = project
    @transactable_classes = transactable_classes
    @target = target
    @options = {
      include_failed: include_failed,
      verified_accounts_only: verified_accounts_only,
      batch: batch && project.transfer_batch_size > 1
    }
  end

  def next_transactions # rubocop:todo Metrics/CyclomaticComplexity
    transactions = []
    transactable_classes.each do |transactable_class|
      next if target[:for] == :hot_wallet && transactable_class == TransferRule
      next if options[:batch] && transactable_class != Award

      transactions = next_transactions_for(transactable_class)

      break if transactions.any?
    end

    transactions
  end

  def next_transactions_for(transactable_class)
    joins_sql = <<~SQL
      LEFT JOIN batch_transactables
      ON batch_transactables.id = (
        SELECT MAX(id)
        FROM batch_transactables
        WHERE batch_transactables.blockchain_transactable_id = #{transactable_class.table_name}.id
        AND batch_transactables.blockchain_transactable_type = '#{transactable_class}'
      )
      LEFT JOIN blockchain_transactions
      ON blockchain_transactions.transaction_batch_id = batch_transactables.transaction_batch_id
    SQL

    where_sql = <<~SQL
      (blockchain_transactions.id IS NULL) OR
      (blockchain_transactions.status IN (:blockchain_transactions_cancelled_statuses)) OR
      (blockchain_transactions.status = :blockchain_transaction_created_status AND blockchain_transactions.created_at < :timestamp)
    SQL

    q = project
        .public_send(transactable_class.table_name)
        .joins(ApplicationRecord.sanitize_sql_array([joins_sql]))
        .distinct
        .where(
          where_sql,
          blockchain_transactions_cancelled_statuses: blockchain_transactions_cancelled_statuses,
          blockchain_transaction_created_status: BlockchainTransaction.statuses[:created],
          timestamp: 10.minutes.ago
        )

    if transactable_class == Award
      q = scopes_for_awards(q)
    elsif transactable_class == AccountTokenRecord
      q = scopes_for_account_token_records(q)
    elsif transactable_class == TransferRule
      q = scopes_for_transfer_rules(q)
    end

    q = filter_unverified_accounts(q, transactable_class) if options[:verified_accounts_only]
    q = filter_for_batch_tx(q) if options[:batch]
    q.limit(project.transfer_batch_size)
  end

  private

    def blockchain_transactions_cancelled_statuses
      statuses = [BlockchainTransaction.statuses[:cancelled]]
      statuses << BlockchainTransaction.statuses[:failed] if options[:include_failed]
      statuses
    end

    def scopes_for_awards(scope)
      scope = scope.accepted.order('awards.prioritized_at DESC nulls last, awards.created_at ASC')
      scope = scope.where('awards.prioritized_at is not null') if hot_wallet_manual?
      scope
    end

    def scopes_for_account_token_records(scope)
      scope = scope.not_synced.order('account_token_records.prioritized_at DESC nulls last, account_token_records.created_at ASC')
      scope = scope.where('account_token_records.prioritized_at is not null') if hot_wallet_manual?
      scope
    end

    def scopes_for_transfer_rules(scope)
      scope.not_synced
    end

    def filter_unverified_accounts(scope, transactable_class)
      verified_joins_sql = <<~SQL
        LEFT JOIN (
          select distinct on (account_id) *
          from verifications
          where passed = true
        ) as account_verified
        ON account_verified.account_id = #{transactable_class.table_name}.account_id
      SQL

      scope.joins(verified_joins_sql).where('account_verified.passed = true')
    end

    def filter_for_batch_tx(scope)
      scope
        .joins(:transfer_type).where.not('transfer_types.name': %w[mint burn])
        .joins(:token).where <<~SQL
          (tokens.batch_contract_address IS NOT NULL) OR
          (tokens._token_type = 13)
        SQL
    end

    def hot_wallet_manual?
      target[:for] == :hot_wallet && project.hot_wallet_manual_sending?
    end
end
