require 'rails_helper'

describe Accounts::Register do
  describe '#call' do
    context 'when the whitelabel mission is present' do
      let!(:whitelabel_mission) { create(:whitelabel_mission) }
      let!(:account_params) { { email: 'example@gmail.com', password: 'password', agreed_to_user_agreement: '1' } }

      subject(:result) do
        described_class.call(whitelabel_mission: whitelabel_mission, account_params: account_params)
      end

      it 'creates whitelabel account' do
        expect(result.success?).to eq(true)

        expect(result.account.managed_account_id).not_to be(nil)
      end
    end

    context 'when the whitelabel mission is nil' do
      let!(:account_params) { { email: 'example@gmail.com', password: 'password', agreed_to_user_agreement: '1' } }

      subject(:result) do
        described_class.call(whitelabel_mission: nil, account_params: account_params)
      end

      it 'creates an account' do
        expect(result.success?).to eq(true)
      end
    end

    context 'when data is invalid' do
      let!(:account_params) { { email: 'example@gmail.com', agreed_to_user_agreement: '1' } }

      subject(:result) do
        described_class.call(whitelabel_mission: nil, account_params: account_params)
      end

      it 'returns fail' do
        expect(result.failure?).to eq(true)

        expect(result.account.errors.full_messages.first).to eq('Password is too short (minimum is 8 characters)')
      end
    end
  end
end
