# frozen_string_literal: true

require 'rails_helper'

describe Transfers::Create do
  describe '#call' do
    subject(:result) do
      described_class.call(issuer: issuer,
                           account_id: recipient.id,
                           award_type: award_type,
                           transfer_params: transfer_params)
    end

    let(:issuer) { FactoryBot.create(:account) }

    let(:recipient) { FactoryBot.create(:account) }

    let(:project) { FactoryBot.create(:project) }

    let(:award_type) { project.default_award_type }

    let(:transfer_type) { FactoryBot.create(:transfer_type, project: project) }

    context 'when given valid data' do
      let(:transfer_params) do
        {
          transfer_type_id: transfer_type.id,
          amount: Faker::Number.number
        }
      end

      it { expect(result).to be_a_success }

      it { expect { result }.to change(Award, :count).by(1) }
    end

    context 'when given invalid data' do
      let(:transfer_params) do
        {
          transfer_type_id: nil,
          amount: Faker::Number.number
        }
      end

      it { expect(result).to be_a_failure }

      it { expect { result }.not_to change(Award, :count) }
    end
  end
end
