class NextBlockchainTransactables
  attr_reader :project, :transactable_classes, :target

  def initialize(project:, target:, transactable_classes: [])
    @project = project
    @transactable_classes = transactable_classes.any? ? transactable_classes : default_transactable_classes
    @target = target
  end

  def call # rubocop:todo Metrics/CyclomaticComplexity
    transactions = []

    transactable_classes.each do |transactable_class|
      next if hot_wallet_disabled?
      next if target_hot_wallet? && !hot_wallet_support?(transactable_class)

      if batch_support?(transactable_class)
        transactions = next_transactables_for(transactable_class, batch_size: project.transfer_batch_size)
        break if transactions.any?
      end

      transactions = next_transactables_for(transactable_class)
      break if transactions.any?
    end

    transactions
  end

  def next_transactables_for(transactable_class, batch_size: 1) # rubocop:todo Metrics/CyclomaticComplexity
    return Token.where(id: project.token_id) if transactable_class == Token

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

    q =
      if transactable_class == Award
        project.awards
      elsif transactable_class == Token
        project.token
      else
        project.token.public_send(transactable_class.table_name)
      end

    q = q.joins(ApplicationRecord.sanitize_sql_array([joins_sql]))
         .distinct
         .where(
           where_sql,
           blockchain_transactions_cancelled_statuses: blockchain_transactions_cancelled_statuses,
           blockchain_transaction_created_status: BlockchainTransaction.statuses[:created],
           timestamp: 10.minutes.ago
         )

    if transactable_class == Award
      q = scopes_for_awards(q, batch_size)
    elsif transactable_class == AccountTokenRecord
      q = scopes_for_account_token_records(q)
    elsif transactable_class == TransferRule
      q = scopes_for_transfer_rules(q)
    end
    q
  end

  private

    def blockchain_transactions_cancelled_statuses
      statuses = [BlockchainTransaction.statuses[:cancelled]]
      statuses << BlockchainTransaction.statuses[:failed] if include_failed?
      statuses
    end

    def scopes_for_awards(scope, batch_size)
      scope = scope.accepted.order('awards.prioritized_at DESC nulls last, awards.created_at ASC')
      scope = scope.where('awards.prioritized_at is not null') if hot_wallet_manual?
      scope = filter_unverified_accounts(scope) if verified_accounts_only?
      scope = filter_for_batch_tx(scope) if batch_size > 1
      scope.limit(batch_size)
    end

    def scopes_for_account_token_records(scope)
      scope = scope.not_synced.order('account_token_records.prioritized_at DESC nulls last, account_token_records.created_at ASC')
      scope = scope.where('account_token_records.prioritized_at is not null') if hot_wallet_manual?
      scope
    end

    def scopes_for_transfer_rules(scope)
      scope.not_synced
    end

    def filter_unverified_accounts(scope)
      join_sql = <<~SQL
        INNER JOIN verifications AS latest_verification
          ON latest_verification.account_id = awards.account_id
      SQL
      scope.joins(join_sql).where('latest_verification.passed = true')
    end

    def filter_for_batch_tx(scope)
      scope
        .joins(:transfer_type).where.not('transfer_types.name': %w[mint burn])
        .joins(:token).where(<<~SQL, erc20: Token._token_types[:erc20], token_release_schedule: Token._token_types[:token_release_schedule])
          (tokens._token_type = :erc20 AND tokens.batch_contract_address IS NOT NULL) OR
          (tokens._token_type = :token_release_schedule)
        SQL
    end

    def default_transactable_classes
      [AccountTokenRecord, Award]
    end

    def target_hot_wallet?
      target == :hot_wallet
    end

    def target_manual?
      target == :manual
    end

    def hot_wallet_disabled?
      target_hot_wallet? && project.hot_wallet_disabled?
    end

    def hot_wallet_manual?
      target_hot_wallet? && project.hot_wallet_manual_sending?
    end

    def hot_wallet_auto?
      target_hot_wallet? && project.hot_wallet_auto_sending?
    end

    def hot_wallet_support?(transactable_class)
      transactable_class.in?([Award, AccountTokenRecord])
    end

    def batch_support?(transactable_class)
      transactable_class == Award && project.transfer_batch_size > 1 && project.token.supports_batch_transfers?
    end

    def verified_accounts_only?
      hot_wallet_auto?
    end

    def include_failed?
      hot_wallet_manual? || target_manual?
    end
end
