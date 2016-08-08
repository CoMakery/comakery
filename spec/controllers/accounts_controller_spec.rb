require 'rails_helper'

describe AccountsController do
  let(:account) { create(:sb_authentication).account }

  before { login(account) }

  describe "#update" do
    it "works" do
      expect do
        put :update, account: {ethereum_wallet: "0x#{'a'*40}"}
        expect(response.status).to eq(302)
      end.to change { account.reload.ethereum_wallet }.from(nil).to("0x#{'a'*40}")

      expect(response).to redirect_to account_url
      expect(flash[:notice]).to eq("Ethereum account updated. If this is an unused account the address will not be visible on the Ethereum blockchain until it is part of a transaction.")
    end

    it "renders errors" do
      expect do
        put :update, account: {ethereum_wallet: "too short and spaces"}
        expect(response.status).to eq(200)
      end.not_to change { account.reload.ethereum_wallet }

      expect(flash[:error]).to eq("Ethereum wallet should start with '0x', followed by a 40 character ethereum address")
      expect(assigns[:current_account]).to be
    end
  end
end
