# frozen_string_literal: true

require 'rails_helper'

describe ReorderTransfersQuery do
  subject(:query) { described_class.new(relation, params) }

  let(:project) { FactoryBot.create(:project) }

  let(:recipient1) { FactoryBot.create(:account, first_name: 'Ben', last_name: 'Schultz') }

  let(:recipient2) { FactoryBot.create(:account, first_name: 'Carolina', last_name: 'Rutherford') }

  let(:issuer1) { FactoryBot.create(:account, first_name: 'Oda', last_name: 'Muller') }

  let(:issuer2) { FactoryBot.create(:account, first_name: 'Florian', last_name: 'Lynch') }

  let!(:award1) { FactoryBot.create(:award, status: :paid, project: project, account: recipient1, issuer: issuer1) }

  let!(:award2) { FactoryBot.create(:award, status: :paid, project: project, account: recipient2, issuer: issuer2) }

  let(:relation) { project.awards }

  let(:params) do
    {
      q: {}
    }
  end

  describe '#call' do
    it { expect(query.call).to contain_exactly(award1, award2) }

    context 'when reorder transfer recipient first name' do
      context 'with ASC order' do
        let(:params) do
          {
            q: {
              s: 'account_first_name asc'
            }
          }
        end

        it '' do
          expect(query.call).to eq([award1, award2])
        end
      end

      context 'with DESC order' do
        let(:params) do
          {
            q: {
              s: 'account_first_name desc'
            }
          }
        end

        it '' do
          expect(query.call).to eq([award2, award1])
        end
      end
    end

    context 'when reorder by transfer issuer first name' do
      context 'with ASC order' do
        let(:params) do
          {
            q: {
              s: 'issuer_first_name asc'
            }
          }
        end

        it { expect(query.call).to eq([award2, award1]) }
      end

      context 'with DESC order' do
        let(:params) do
          {
            q: {
              s: 'issuer_first_name desc'
            }
          }
        end

        it { expect(query.call).to eq([award1, award2]) }
      end
    end
  end
end
