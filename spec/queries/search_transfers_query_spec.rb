# frozen_string_literal: true

require 'rails_helper'

describe SearchTransfersQuery do
  describe '#call' do
    subject(:query) { described_class.new(relation, params) }

    let(:project) { FactoryBot.create(:project) }

    let(:paid_award) { FactoryBot.create(:award, status: :paid, project: project) }

    let(:cancelled_award) { FactoryBot.create(:award, status: :cancelled, project: project) }

    let(:relation) { project.awards }

    context 'when search by cancelled status' do
      let(:params) do
        {
          q: {
            filter: 'cancelled',
            status_eq: '6'
          }
        }
      end

      it { expect(query.call.result).to contain_exactly(cancelled_award) }
    end

    context 'when there is no filter by cancelled status' do
      let(:params) do
        {
          q: {}
        }
      end

      it 'always exclude cancelled awards from search' do
        expect(query.call.result).to contain_exactly(paid_award)
      end
    end
  end
end
