require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'X. Tokens' do
  include Rails.application.routes.url_helpers

  before do
    Timecop.freeze(Time.local(2021, 4, 6, 10, 5, 0))
    allow_any_instance_of(Comakery::APISignature).to receive(:nonce).and_return('0242d70898bcf3fbb5fa334d1d87804f')
  end

  after do
    Timecop.return
  end

  let!(:active_whitelabel_mission) { create(:mission, whitelabel: true, whitelabel_domain: 'example.org', whitelabel_api_public_key: build(:api_public_key), whitelabel_api_key: build(:api_key)) }
  let!(:account) { create(:account, managed_mission: active_whitelabel_mission) }

  explanation ['Retrieve data tokens. '\
              'Inflection is managed via `Key-Inflection` request header with values of `camel`, `dash`, `snake` or `pascal`.
               By default requests use snake case, responses use camel case.'].join(' ')

  header 'API-Key', build(:api_key)
  header 'Content-Type', 'application/json'

  get '/api/v1/tokens' do
    with_options with_example: true do
      response_field :id, 'id', type: :integer
      response_field :name, 'name', type: :string
      response_field :symbol, 'symbol', type: :string
      response_field :network, 'network', type: :string
      response_field :contractAddress, 'contact address', type: :string
      response_field :decimalPlaces, 'decimal places', type: :string
      response_field :imageUrl, 'image url', type: :string
      response_field :createdAt, 'token creation timestamp', type: :string
      response_field :updatedAt, 'token update timestamp', type: :string
    end

    context '200' do
      let!(:cat_token) { create(:static_token, id: 20, name: 'Cats') }
      let!(:dog_token) { create(:static_token, id: 25, name: 'Dogs', _blockchain: 'cardano', symbol: 'TKN676f3ac72f320bb17911868a001314e3533cd150') }

      example 'GET' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')

        result = do_request(request)
        result[0][:response_headers]['ETag'] = 'W/"294c784ecfd71841bea5933ffa76de40"' if status == 200
        expect(status).to eq(200)
      end

      example 'GET – FILTERING WITH OR CONDITION' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')
        request[:q] = { name_or_symbol_cont: 'Cats' }

        result = do_request(request)
        result[0][:response_headers]['ETag'] = 'W/"295caf1489fb5ec5cc0ae211203e0b3d"' if status == 200
        expect(status).to eq(200)
      end

      example 'GET – FILTERING WITH AND CONDITION' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')
        request[:q] = { name_cont: 'Dogs', network_eq: 'cardano' }

        result = do_request(request)
        result[0][:response_headers]['ETag'] = 'W/"a94e98e98c6628d6add2e34b52b7daac"' if status == 200
        expect(status).to eq(200)
      end
    end

    context '400' do
      let!(:cat_token) { create(:token, id: 40, name: 'Cats') }

      example 'INDEX – ERROR' do
        explanation 'Returns an array of errors'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')
        request[:q] = { network_cont: 'bitcoin' }

        do_request(request)
        expect(status).to eq(400)
      end
    end
  end
end
