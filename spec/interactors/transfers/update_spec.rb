# frozen_string_literal: true

require 'rails_helper'

describe Transfers::Update do
  describe '#call' do
    subject(:result) { described_class.call(transfer: transfer, transfer_params: transfer_params) }

    let(:project) { FactoryBot.create(:project) }

    let(:award_type) { FactoryBot.create(:award_type, project: project) }

    let(:transfer_type) { project.transfer_types.find_by(name: 'earned') }

    let(:transfer) do
      FactoryBot.create(:award, project: project, transfer_type: transfer_type,
                                created_at: Time.zone.local(2015, 3, 24), amount: 5, quantity: 2,
                                award_type: award_type)
    end

    context 'when given valid data' do
      let(:transfer_params) do
        {
          amount: Faker::Number.number
        }
      end

      it { expect(result).to be_a_success }
    end

    context 'when given invalid data' do
      let(:transfer_params) do
        {
          amount: Faker::Number.negative
        }
      end

      it { expect(result).to be_a_failure }

      it { expect(result.error).to eq('Amount must be greater than or equal to 0') }
    end
  end
end
