# frozen_string_literal: true

module Transfers
  class Update
    include Interactor

    def call
      context.fail!(error: context.transfer.errors.full_messages.join(', ')) unless context.transfer.update(context.transfer_params)
    end
  end
end
