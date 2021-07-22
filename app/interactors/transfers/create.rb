# frozen_string_literal: true

module Transfers
  class Create
    include Interactor

    def call
      transfer = context.award_type.awards.new(context.transfer_params)

      transfer.name = transfer.transfer_type&.name&.titlecase

      transfer.account_id = context.account_id

      transfer.issuer = context.issuer

      transfer.status = :accepted

      if transfer.save
        context.transfer = transfer
      else
        context.fail!(error: transfer.errors.full_messages.join(', '))
      end
    end
  end
end
