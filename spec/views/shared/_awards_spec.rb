require 'rails_helper'

describe 'shared/_awards.html.rb' do
  let!(:team) { create :team }
  let!(:issuer) { create(:account) }
  let!(:recipient1) { create(:account) }
  let!(:recipient2) { create(:account) }
  let!(:issuer_auth) { create(:authentication, account: issuer) }
  let!(:recipient1_auth) { create(:authentication, account: recipient1) }
  let!(:recipient2_auth) { create(:authentication, account: recipient2) }
  let!(:project) do
    stub_token_symbol
    create(:project, account: issuer, token: create(:token, ethereum_enabled: true, contract_address: '0x583cbbb8a8443b38abcc0c956bece47340ea1367', _token_type: 'erc20', _blockchain: :ethereum_ropsten))
  end
  let!(:award_type) { create(:award_type, project: project) }
  let!(:award1) { create(:award, award_type: award_type, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }
  let!(:award2) { create(:award, award_type: award_type, description: 'awesome', issuer: issuer, account: recipient2).decorate }

  before do
    team.build_authentication_team issuer_auth
    team.build_authentication_team recipient1_auth
    team.build_authentication_team recipient2_auth
  end

  before { assign :project, project.decorate }
  before { assign :awards, [award1] }
  before { assign :show_recipient, true }
  before { assign :current_account, issuer }

  describe 'Description column' do
    it 'renders mardown as HTML' do
      render
      assert_select '.description', html: %r{markdown <em>rocks</em>:}
      assert_select '.description', html: %r{<a href="http://www.auto.link"[^>]*>www.auto.link</a>}
    end
  end

  describe 'awards history' do
    before do
      award1.update(quantity: 2, unit_amount: 5, total_amount: 10)
      render
    end

    specify do
      expect(rendered).to have_css '.award-unit-amount', text: '5'
    end

    specify do
      expect(rendered).to have_css '.award-quantity', text: '2'
    end

    specify do
      expect(rendered).to have_css '.award-total-amount', text: '10'
    end
  end

  describe 'Blockchain Transaction column' do
    describe 'when project is ethereum enabled' do
      describe 'with award ethereum transaction address' do
        before { award1.ethereum_transaction_address = '0x34567890123456789' }
        it 'shows the blockchain award when it exists' do
          render
          expect(rendered).to have_css '.blockchain-address a', text: '0x34567890...'
        end
      end

      describe 'with no award ethereum transaction address' do
        describe 'when issuer could send award' do
          before do
            assign :current_account, issuer
          end
          context '_token_type eq erc20' do
            before do
              recipient1.ethereum_wallet = '0x123'
              project.token.contract_address = '0x' + 'a' * 40
              project.token._token_type = 'erc20'
              project.token._blockchain = 'ethereum'
            end
            it 'display Metamask icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Metamask2]'
            end
          end

          context '_token_type eq eth' do
            before do
              recipient1.ethereum_wallet = '0x123'
              project.token._token_type = 'eth'
              project.token._blockchain = 'ethereum'
            end
            it 'display Metamask icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Metamask2]'
            end
          end

          context '_token_type eq qrc20' do
            let!(:project2) do
              create(:project, account: issuer, token: create(:token, ethereum_enabled: true, contract_address: '8cfe9e9893e4386645eae8107cd53aaccf96b7fd', _token_type: 'qrc20', _blockchain: 'qtum_test'))
            end
            let!(:award_type2) { create(:award_type, project: project2) }
            let!(:award2) { create(:award, award_type: award_type2, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }

            before do
              recipient1.qtum_wallet = 'q123'
              assign :project, project2.decorate
              assign :awards, [award2]
            end
            it 'display Qrypto icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Qrypto]'
            end
          end

          context '_token_type eq qtum' do
            let!(:project2) do
              create(:project, account: issuer, token: create(:token, ethereum_enabled: true, _token_type: 'qtum', _blockchain: 'qtum_test'))
            end
            let!(:award_type2) { create(:award_type, project: project2) }
            let!(:award2) { create(:award, award_type: award_type2, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }

            before do
              recipient1.qtum_wallet = 'q123'
              assign :project, project2.decorate
              assign :awards, [award2]
            end
            it 'display Ledger icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Ledger]'
            end
          end

          context '_token_type eq ada' do
            let!(:project2) do
              create(:project, account: issuer, token: create(:token, ethereum_enabled: true, _token_type: 'ada', _blockchain: 'cardano'))
            end
            let!(:award_type2) { create(:award_type, project: project2) }
            let!(:award2) { create(:award, award_type: award_type2, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }

            before do
              recipient1.cardano_wallet = 'Ae2tdPwUPEZ3uaf7wJVf7ces9aPrc6Cjiz5eG3gbbBeY3rBvUjyfKwEaswp'
              assign :project, project2.decorate
              assign :awards, [award2]
            end
            it 'display Trezor icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Trezor]'
            end
          end

          context '_token_type eq eos' do
            let!(:project2) do
              create(:project, account: issuer, token: create(:token, ethereum_enabled: true, _token_type: 'eos', _blockchain: 'eos'))
            end
            let!(:award_type2) { create(:award_type, project: project2) }
            let!(:award2) { create(:award, award_type: award_type2, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }

            before do
              recipient1.eos_wallet = 'aaatestnet11'
              assign :project, project2.decorate
              assign :awards, [award2]
            end
            it 'display eos icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Eos]'
            end
          end

          context '_token_type eq xtz' do
            let!(:project2) do
              create(:project, account: issuer, token: create(:token, ethereum_enabled: true, _token_type: 'xtz', _blockchain: 'tezos'))
            end
            let!(:award_type2) { create(:award_type, project: project2) }
            let!(:award2) { create(:award, award_type: award_type2, description: 'markdown _rocks_: www.auto.link', issuer: issuer, account: recipient1).decorate }

            before do
              recipient1.tezos_wallet = 'tz1Zbe9hjjSnJN2U51E5W5fyRDqPCqWMCFN9'
              assign :project, project2.decorate
              assign :awards, [award2]
            end
            it 'display Tezos icon on Send button' do
              render
              expect(rendered).to have_css 'img[alt=Tezos]'
            end
          end
        end

        describe 'when recipient ethereum address is present' do
          before do
            recipient1.ethereum_wallet = '0x123'
            project.account = nil
          end
          it 'says "pending"' do
            render
            expect(rendered).to have_css '.blockchain-address', text: 'pending'
          end
        end

        describe 'when recipient ethereum address is blank' do
          before { recipient1.ethereum_wallet = nil }
          describe 'when logged in as award recipient' do
            before { assign :current_account, recipient1 }
            it 'links to their account' do
              render
              expect(rendered).to have_css '.blockchain-address a[href="/account"]', text: 'no account'
            end
          end

          describe 'when logged in as another user' do
            before { assign :current_account, recipient2 }
            it 'says "no account"' do
              render
              expect(rendered).to have_css '.blockchain-address', text: 'no account'
              expect(rendered).not_to have_css '.blockchain-address a'
            end
          end

          describe 'when not logged in' do
            before { assign :current_account, nil }
            it 'says "no account"' do
              render
              expect(rendered).to have_css '.blockchain-address', text: 'no account'
              expect(rendered).not_to have_css '.blockchain-address a'
            end
          end
        end
      end
    end
  end
end
