require 'rails_helper'
require Rails.root.join('db/data_migrations/20210629004508_populate_recipient_wallet_for_awards')

describe PopulateRecipientWalletForAwards do
  subject { described_class.new.up }

  context 'when award has recipient wallet' do
    let!(:award) { FactoryBot.create(:award, :ropsten, :paid, :with_recipient_wallet) }

    specify do
      expect_any_instance_of(Award).not_to receive(:populate_recipient_wallet)
      subject
    end
  end

  context 'when award doesnt have recipient wallet' do
    let!(:award) { FactoryBot.create(:award, :ropsten, :paid) }

    context 'and doesnt have account' do
      let!(:award) { FactoryBot.create(:award, :ropsten, :paid, account: nil, issuer: FactoryBot.create(:account)) }

      specify do
        expect_any_instance_of(Award).not_to receive(:populate_recipient_wallet)
        subject
      end
    end

    context 'and account doesnt have a wallet' do
      specify do
        subject
        award.reload

        expect(award.recipient_wallet).to eq(nil)
      end
    end

    context 'and account has a wallet' do
      let!(:wallet) { FactoryBot.create(:wallet, :ropsten, account: award.account) }

      specify do
        expect_any_instance_of(Award).to receive(:populate_recipient_wallet).and_call_original
        subject
        award.reload

        expect(award.recipient_wallet).to eq(wallet)
      end
    end
  end
end
