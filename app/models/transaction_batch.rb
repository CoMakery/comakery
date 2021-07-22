class TransactionBatch < ApplicationRecord
  has_one :blockchain_transaction, dependent: :nullify
  has_many :batch_transactables, dependent: :nullify
  has_many :blockchain_transactables_awards, through: :batch_transactables, source: :blockchain_transactable, source_type: 'Award'
  has_many :blockchain_transactables_account_token_records, through: :batch_transactables, source: :blockchain_transactable, source_type: 'AccountTokenRecord'
  has_many :blockchain_transactables_transfer_rules, through: :batch_transactables, source: :blockchain_transactable, source_type: 'TransferRule'
  has_many :blockchain_transactables_tokens, through: :batch_transactables, source: :blockchain_transactable, source_type: 'Token'
  has_many :blockchain_transactables_token_opt_ins, through: :batch_transactables, source: :blockchain_transactable, source_type: 'TokenOptIn'

  def blockchain_transactables=(transactables)
    if transactables.respond_to?(:each)
      transactables.each do |transactable|
        self.blockchain_transactables = transactable
      end
    else
      batch_transactables.create!(blockchain_transactable: transactables)
    end
  end
end
