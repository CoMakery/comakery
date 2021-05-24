require 'rails_helper'

describe ProjectDecorator do
  let(:amount_with_24_decimal_precision) { BigDecimal('9.999_999_999_999_999_999_999') }
  let(:project) { (create :project, maximum_tokens: 1000000000).decorate }
  let(:award_type) { create :award_type, project: project }

  describe '#description_html' do
    let(:project) do
      create(:project,
             description: 'Hi [google](http://www.google.com)')
        .decorate
    end

    specify do
      expect(project.description_html).to include('Hi <a href="http://www.google.com"')
    end
  end

  describe '#description_text_truncated' do
    let(:project) do
      create(:project,
             description: '[Hola](http://google.com) ' + 'a' * 1000)
        .decorate
    end

    specify do
      length_including_dots = 500
      expect(project.description_text_truncated(500).length).to eq(length_including_dots)
    end

    it 'ends with "..."' do
      truncated_description = project.description_text_truncated
      last_char = truncated_description.length
      start_of_end = last_char - 4
      expect(truncated_description[start_of_end, last_char]).to eq('a...')
    end

    it 'does not include html' do
      expect(project.description_text_truncated).not_to include("<a href='http://google.com'")
      expect(project.description_text_truncated).to include('Hola')
    end

    it 'can pass in a max length' do
      expect(project.description_text_truncated(8)).to eq('Hola ...')
    end

    it 'can use a length longer than the string length' do
      project = create(:project, description: 'hola').decorate
      expect(project.description_text_truncated(100)).to eq('hola')
    end
  end

  describe '#status_description' do
    specify do
      project.update license_finalized: true
      expect(project.status_description).to include('finalized and legally binding')
    end

    specify do
      project.update license_finalized: false
      expect(project.status_description).to include('not legally binding')
    end
  end

  describe '#currency_denomination' do
    specify do
      project.token.update denomination: 'USD'
      expect(project.currency_denomination).to eq('$')
    end

    specify do
      project.token.update denomination: 'BTC'
      expect(project.currency_denomination).to eq('฿')
    end

    specify do
      project.token.update denomination: 'ETH'
      expect(project.currency_denomination).to eq('Ξ')
    end
  end

  describe '#payment_description' do
    specify do
      project.project_token!
      expect(project.payment_description).to eq('Project Tokens')
    end
  end

  describe '#outstanding_award_description' do
    specify do
      project.project_token!
      expect(project.outstanding_award_description).to eq('Project Tokens')
    end
  end

  describe 'require_confidentiality_text' do
    specify do
      project.require_confidentiality = true
      expect(project.require_confidentiality_text).to eq('is required')
    end

    specify do
      project.require_confidentiality = false
      expect(project.require_confidentiality_text).to eq('is not required')
    end
  end

  describe 'exclusive_contributions_text' do
    specify do
      project.exclusive_contributions = true
      expect(project.exclusive_contributions_text).to eq('are exclusive')
    end

    specify do
      project.exclusive_contributions = false
      expect(project.exclusive_contributions_text).to eq('are not exclusive')
    end
  end

  describe '#total_awarded_pretty' do
    before do
      create(:award, award_type: award_type, quantity: 1000, amount: 1337, issuer: project.account, account: create(:account))
    end

    specify { expect(project.total_awarded_pretty).to eq('1,337,000.00000000') }
  end

  describe '#total_awarded' do
    specify do
      expect(project)
        .to receive(:total_awarded)
        .and_return(1_234_567)

      expect(project.total_awarded_pretty)
        .to eq('1,234,567.00000000')
    end
  end

  describe '#total_awarded_to_user' do
    specify do
      account = create(:account)
      create(:award, award_type: award_type, amount: 1337, account: account)
      expect(project.total_awarded_to_user(account))
        .to eq('1,337.00000000')
    end
  end

  it '#contributors_by_award_amount' do
    expect(project.contributors_by_award_amount).to eq []
  end

  it 'maximum_tokens_pretty' do
    expect(project.maximum_tokens_pretty).to eq '1,000,000,000'
  end

  it 'format_with_decimal_places' do
    project.token.update decimal_places: 3
    expect(project.format_with_decimal_places(10)).to eq '10.000'
  end

  it 'format_with_decimal_places with no token associated' do
    project.update(token: nil)
    expect(project.format_with_decimal_places(10)).to eq '10'
  end

  describe 'header_props' do
    let!(:project) { create(:project) }
    let!(:award_type) { create(:award_type, project: project, state: 'public') }
    let!(:unlisted_project) { create(:project, visibility: 'public_unlisted') }
    let!(:project_wo_image) { create(:project) }
    let!(:project_comakery_token) { create(:project, token: create(:token, _token_type: :comakery_security_token, contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten)) }

    it 'includes required data for project header component' do
      props = project.decorate.header_props
      props_unlisted = unlisted_project.decorate.header_props
      project_wo_image.update(panoramic_image: nil)
      props_wo_image = project_wo_image.decorate.header_props
      props_w_comakery = project_comakery_token.decorate.header_props

      expect(props[:title]).to eq(project.title)
      expect(props[:owner]).to eq(project.legal_project_owner)
      expect(props[:present]).to be_truthy
      expect(props[:show_batches]).to be_truthy
      expect(props[:show_transfers]).to be_truthy
      expect(props[:supports_transfer_rules]).to be_falsey
      expect(props_w_comakery[:supports_transfer_rules]).to be_truthy
      expect(props[:image_url]).to include('image.png')
      expect(props[:access_url]).to include(project.id.to_s)
      expect(props[:settings_url]).to include(project.id.to_s)
      expect(props[:batches_url]).to include(project.id.to_s)
      expect(props[:transfers_url]).to include(project.id.to_s)
      expect(props[:accounts_url]).to include(project.id.to_s)
      expect(props[:transfer_rules_url]).to include(project.id.to_s)
      expect(props[:landing_url]).to include(project.id.to_s)
      expect(props_unlisted[:landing_url]).to include(unlisted_project.long_id.to_s)
      expect(props_wo_image[:image_url]).to include('default_project')
    end
  end

  describe 'token_props' do
    context 'when token present' do
      let!(:project_comakery_token) do
        create(:project,
               token: create(:token, _token_type: :comakery_security_token,
                                     contract_address: build(:ethereum_contract_address), _blockchain: :ethereum_ropsten))
      end

      let!(:token) { project_comakery_token.token }

      subject(:props) { project_comakery_token.decorate.token_props }

      it 'returns token data' do
        expect(props[:token][:name]).to eq(token.name)
        expect(props[:token][:symbol]).to eq(token.symbol)
        expect(props[:token][:network]).to eq(token.blockchain.name)
        expect(props[:token][:address]).to eq(token.contract_address)
        expect(props[:token][:logo_url]).to include('dummy_image.png')
      end
    end

    context 'when token is nil' do
      let!(:project) { create(:project, token: nil) }

      subject(:props) { project.decorate.token_props }

      it { expect(props).to be_empty }
    end
  end

  describe 'step_for_amount_input' do
    let(:token) { create(:token, decimal_places: 2) }
    let(:project) { create(:project, token: token) }

    it 'returns minimal step for amount input field based on decimal places of token' do
      expect(project.decorate.step_for_amount_input).to eq(0.01)
    end

    it 'returns 1 as a step for amount input field when token is not present' do
      project.update(token: nil)
      project.reload

      expect(project.decorate.step_for_amount_input).to eq(1)
    end
  end

  describe 'step_for_quantity_input' do
    let(:token) { create(:token, decimal_places: 2) }
    let(:project) { create(:project, token: token) }

    it 'returns 0.1 as a step for amount input field' do
      expect(project.decorate.step_for_quantity_input).to eq(0.1)
    end

    it 'returns 1 as a step for amount input field when token is not present' do
      project.update(token: nil)
      project.reload

      expect(project.decorate.step_for_quantity_input).to eq(1)
    end
  end

  describe 'image_url' do
    let!(:project) { create :project }

    it 'returns image_url if present' do
      expect(project.decorate.image_url).to include('dummy_image.png')
    end

    it 'returns default image' do
      project.update(square_image: nil)
      expect(project.reload.decorate.image_url).to include('default_project')
    end
  end

  describe 'transfers_stacked_chart' do
    let!(:project) { create(:project, token: create(:token, contract_address: '0x8023214bf21b1467be550d9b889eca672355c005', _token_type: :comakery_security_token, _blockchain: :ethereum_ropsten)) }

    before do
      create(:award, amount: 1, transfer_type: project.transfer_types.find_by(name: 'mint'), award_type: create(:award_type, project: project))
      create(:award, amount: 2, transfer_type: project.transfer_types.find_by(name: 'mint'), award_type: create(:award_type, project: project))
      create(:award, amount: 5, transfer_type: project.transfer_types.find_by(name: 'burn'), award_type: create(:award_type, project: project))
    end

    it 'sums awards by timeframe' do
      r = project.decorate.transfers_stacked_chart_day(project.awards.completed)
      expect(r.last['mint']).to eq(3)
      expect(r.last['burn']).to eq(5)
    end

    it 'sets defaults' do
      r = project.decorate.transfers_stacked_chart_day(project.awards.completed)
      expect(r.last['earned']).to eq(0)
    end
  end

  describe 'transfers_donut_chart' do
    let!(:project) { create(:project, token: create(:token, contract_address: '0x8023214bf21b1467be550d9b889eca672355c005', _token_type: :comakery_security_token, _blockchain: :ethereum_ropsten)) }

    before do
      create(:award, amount: 1, transfer_type: project.transfer_types.find_by(name: 'mint'), award_type: create(:award_type, project: project))
      create(:award, amount: 2, transfer_type: project.transfer_types.find_by(name: 'mint'), award_type: create(:award_type, project: project))
      create(:award, amount: 5, transfer_type: project.transfer_types.find_by(name: 'burn'), award_type: create(:award_type, project: project))
    end

    it 'sums awards by type' do
      r = project.decorate.transfers_donut_chart(project.awards.completed)
      expect(r.find { |x| x[:name] == 'mint' }[:value]).to eq(3)
      expect(r.find { |x| x[:name] == 'burn' }[:value]).to eq(5)
    end

    it 'sets defaults' do
      r = project.decorate.transfers_donut_chart(project.awards.completed)
      expect(r.find { |x| x[:name] == 'earned' }[:value]).to eq(0)
    end
  end

  describe 'ratio_pretty' do
    context 'when total is zero' do
      it 'returns 100 %' do
        expect(project.ratio_pretty(1, 0)).to eq('100 %')
      end
    end

    context 'when ratio is zero' do
      it 'returns < 1 %' do
        expect(project.ratio_pretty(0, 1)).to eq('< 1 %')
      end
    end

    context 'when ratio is 100' do
      it 'returns 100 %' do
        expect(project.ratio_pretty(1, 1)).to eq('100 %')
      end
    end

    it 'returns ratio' do
      expect(project.ratio_pretty(1, 2)).to eq('≈ 50 %')
    end
  end
end
