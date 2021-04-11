require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'I. General' do
  include Rails.application.routes.url_helpers

  let!(:active_whitelabel_mission) { create(:mission, id: 999, created_at: build(:static_timestamp), updated_at: build(:static_timestamp), whitelabel: true, whitelabel_domain: 'example.org', whitelabel_api_public_key: build(:api_public_key), whitelabel_api_key: build(:api_key)) }
  let!(:project) { create(:project,
                          id: 999,
                          created_at: build(:static_timestamp),
                          mission: active_whitelabel_mission,
                          token: create(:comakery_token,
                                        id: 999,
                                        name: 'ComakeryToken-4d38e48b6c32993893db2b4a1f9e1162361762a6',
                                        symbol: 'XYZ90a27bfa779972c98a07b6b67567de4bd4a32bb5',
                                        created_at: build(:static_timestamp)
                                        )
                          )
                  }

  before do
    project.transfer_types.each_with_index do |t_type, i|
      t_type.update_column(:id, 905+i)
    end
    project.update_column(:updated_at, build(:static_timestamp))
    project.token.update_column(:updated_at, build(:static_timestamp))
  end

  explanation 'Details on authentication, caching, throttling, inflection and pagination.'

  header 'API-Key', build(:api_key)

  get '/api/v1/projects' do
    with_options scope: :body, with_example: true do
      parameter :data, 'request data', required: true
      parameter :url, 'request url', required: true
      parameter :method, 'request http method', required: true
      parameter :nonce, 'request nonce (rotated every 24h)', required: true
      parameter :timestamp, 'request timestamp (expires in 60 seconds)', required: true
    end

    with_options scope: :proof, with_example: true do
      parameter :type, 'Ed25519Signature2018', required: true
      parameter :verificationMethod, 'public key', required: true
      parameter :signature, 'request signature', required: true
    end

    context '200' do
      example 'AUTHENTICATION' do
        explanation [
          'Requests should include `API-Key` header and a correct proof based on `Ed25519Signature2018` in the format described below.' \
          'All values should be strings.' \
          'Note 1: When calculating the signature, request data should be serialized according JSON Canonicalization Scheme.' \
          'Note 2: Blockchain Transactions (VII) endpoints do not require proof and can be accessed with either `API-Key` or `API-Transaction-Key` header. See section VII for examples.'
        ].join(' ')

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        result = do_request(request)
        if status == 200
          result[0][:response_headers]['ETag'] = 'ETag: W/"65619e25d426a61fdaaea38f54f63b1f"'
          result[0][:response_headers]['Last-Modified'] = 'Mon, 05 Apr 2021 11:08:13 GMT'
        end
        expect(status).to eq(200)
      end
    end
  end

  get '/api/v1/projects' do
    header 'API-Key', '12345'

    context '401' do
      example 'AUTHENTICATION – INCORRECT PUBLIC KEY HEADER' do
        explanation 'Requests with incorrect public key header will be denied.'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        do_request(request)
        expect(status).to eq(401)
      end
    end
  end

  get '/api/v1/projects' do
    context '401' do
      example 'AUTHENTICATION – INCORRECT PROOF' do
        explanation 'Requests with incorrect proof, url, method, timestamp or nonce will be denied.'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example1.org')
        do_request(request)
        expect(status).to eq(401)
      end
    end
  end

  get '/api/v1/projects' do
    header 'If-Modified-Since', :if_modified

    context '304' do
      let!(:if_modified) { project.updated_at.httpdate }

      example 'CACHING' do
        explanation 'Responses include weak `ETag` and `Last-Modified` headers. Server will return HTTP 304 when applicable if request includes valid `If-Modified-Since` header.'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        result = do_request(request)
        if status == 304
          result[0][:response_headers]['ETag'] = 'W/"e1ecbd938491cc1765caf2c0ea693a2c"'
          result[0][:response_headers]['Last-Modified'] = 'Mon, 05 Apr 2021 11:52:40 GMT'
          result[0][:request_headers]['If-Modified-Since'] = 'Mon, 05 Apr 2021 11:52:40 GMT'
        end
        expect(status).to eq(304)
      end
    end
  end

  get '/api/v1/projects' do
    context '429' do
      before do
        Rails.cache.write("rack::attack:#{Time.now.to_i / 60}:api/ip:127.0.0.1", 1001)
      end

      after do
        Rails.cache.clear
      end

      example 'THROTTLING' do
        explanation 'Requests are throttled to 1000rpm per origin to avoid service interruption. On exceeding the limit server will return HTTP 429.'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        do_request(request)
        expect(status).to eq(429)
      end
    end
  end

  get '/api/v1/projects' do
    header 'Key-Inflection', :key_inflection

    context '200' do
      let!(:key_inflection) { 'dash' }

      example 'INFLECTION' do
        explanation 'Inflection is managed via `Key-Inflection` request header with values of `camel`, `dash`, `snake` or `pascal`. By default requests use snake case, responses use camel case.'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        result = do_request(request)
        if status == 200
          result[0][:response_headers]['Last-Modified'] = 'Mon, 05 Apr 2021 11:52:40 GMT'
          result[0][:response_headers]['ETag'] = 'W/"e1ecbd938491cc1765caf2c0ea693a2c"'
        end
        expect(status).to eq(200)
      end
    end
  end

  get '/api/v1/projects' do
    with_options with_example: true do
      parameter :page, 'page number', type: :integer
    end

    context '200' do
      let!(:page) { 1 }

      example 'PAGINATION' do
        explanation 'Pagination is implemented according RFC-8288 (`Page` request parameter; `Link`, `Total`, `Per-Page` response headers).'

        request = build(:api_signed_request, '', api_v1_projects_path, 'GET', 'example.org')
        result = do_request(request)
        if status == 200
          result[0][:response_headers]['Last-Modified'] = 'Mon, 05 Apr 2021 12:15:05 GMT'
          result[0][:response_headers]['ETag'] = 'W/"5fa3c6359b49359241b800a7b6135cbe"'
        end
        expect(status).to eq(200)
      end
    end
  end
end
