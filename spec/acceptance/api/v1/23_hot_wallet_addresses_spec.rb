require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'XII. Hot Wallet Addresses' do
  include Rails.application.routes.url_helpers

  before do
    Timecop.freeze(Time.local(2021, 4, 6, 10, 5, 0))
    allow_any_instance_of(Comakery::APISignature).to receive(:nonce).and_return('0242d70898bcf3fbb5fa334d1d87804f')
  end

  after do
    Timecop.return
  end

  let!(:active_whitelabel_mission) { create(:mission, whitelabel: true, whitelabel_domain: 'example.org', whitelabel_api_public_key: build(:api_public_key), whitelabel_api_key: build(:api_key)) }
  let!(:project) { create(:project, id: 45, mission: active_whitelabel_mission, api_key: ApiKey.new(key: build(:api_key))) }

  let(:valid_attributes) { { address: build(:wallet).address } }

  explanation 'Register hot wallets with a project.'

  header 'API-Transaction-Key', build(:api_key)
  header 'Content-Type', 'application/json'

  post '/api/v1/projects/:project_id/hot_wallet_addresses' do
    with_options with_example: true do
      parameter :name, 'wallet name ("Hot Wallet" by default)', required: false, type: :string
      parameter :address, 'wallet address', required: true, type: :string
    end

    context '201' do
      let!(:project_id) { project.id }
      let!(:create_params) { { hot_wallet: valid_attributes } }

      example 'CREATE HOT WALLET' do
        explanation 'Returns created hot wallet'

        params = { body: { data: create_params } }
        allow_any_instance_of(Wallet).to receive(:id).and_return(20)
        result = do_request(params)
        if status == 201
          result[0][:request_headers]['Api-Transaction-Key'] = '28ieQrVqi5ZQXd77y+pgiuJGLsFfwkWO'
          result[0][:response_headers]['ETag'] = 'W/"358c175d70eb36a20062399b82387311"'
        end
        expect(status).to eq(201)
      end
    end

    context '422' do
      let!(:project_id) { project.id }
      let!(:create_params) { { hot_wallet: valid_attributes } }

      before do
        create(:wallet, source: :hot_wallet, project_id: project.id)
      end

      example 'CREATE HOT WALLET – ERROR' do
        explanation 'Returns an array of errors'

        params = { body: { data: create_params } }
        result = do_request(params)
        result[0][:request_headers]['Api-Transaction-Key'] = '28ieQrVqi5ZQXd77y+pgiuJGLsFfwkWO' if status == 422
        expect(status).to eq(422)
      end
    end
  end
end
