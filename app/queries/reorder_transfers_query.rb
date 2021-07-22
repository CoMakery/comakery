# frozen_string_literal: true

class ReorderTransfersQuery
  def initialize(relation, params)
    @relation = relation
    @params = params
  end

  def call
    return Award.none if relation.blank?

    relation.includes(relationships).ransack_reorder(reorder_params)
  end

  private

    attr_reader :relation, :params

    def relationships
      [
        :project,
        :token,
        :transfer_type,
        :recipient_wallet,
        award_type: [
          :project
        ],
        issuer: [
          image_attachment: :blob
        ],
        account: [
          :ore_id_account,
          :latest_verification,
          image_attachment: :blob
        ]
      ]
    end

    def reorder_params
      params.dig(:q, :s)
    end
end
