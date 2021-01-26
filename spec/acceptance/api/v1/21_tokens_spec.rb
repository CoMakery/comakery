require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'X. Tokens' do
  include Rails.application.routes.url_helpers

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
      let!(:cat_token) { create(:token, name: 'Cats') }
      let!(:dog_token) { create(:token, name: 'Dogs', _blockchain: 'cardano') }

      example 'GET' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')

        do_request(request)
        expect(status).to eq(200)
      end

      example 'GET – FILTERING WITH OR CONDITION' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')
        request[:q] = { name_or_symbol_cont: 'Cats' }

        do_request(request)
        expect(status).to eq(200)
      end

      example 'GET – FILTERING WITH AND CONDITION' do
        explanation 'Returns tokens.'

        request = build(:api_signed_request, '', api_v1_tokens_path, 'GET', 'example.org')
        request[:q] = { name_cont: 'Dogs', network_eq: 'cardano' }

        do_request(request)
        expect(status).to eq(200)
      end
    end

    context '400' do
      let!(:cat_token) { create(:token, name: 'Cats') }

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
