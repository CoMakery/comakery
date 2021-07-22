# frozen_string_literal: true

class SearchTransfersQuery
  def initialize(relation, params)
    @relation = relation
    @params = params
  end

  def call
    if filter_params.eql?('cancelled')
      relation.ransack(search_params)
    else
      relation.not_cancelled.ransack(search_params)
    end
  end

  private

    attr_reader :relation, :params

    def filter_params
      params.fetch(:q, {}).fetch(:filter, {})
    end

    def search_params
      params[:q]
    end
end
