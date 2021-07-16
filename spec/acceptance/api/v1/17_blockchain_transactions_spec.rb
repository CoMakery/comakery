require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'VII. Blockchain Transactions' do
  include Rails.application.routes.url_helpers

  before do
    Timecop.freeze(Time.zone.local(2021, 4, 6, 10, 5, 0))
    allow_any_instance_of(Comakery::APISignature).to receive(:nonce).and_return('0242d70898bcf3fbb5fa334d1d87804f')
    allow_any_instance_of(Api::V1::BlockchainTransactionsController).to receive(:nonce_unique?).and_return(true)
    allow_any_instance_of(ApiKey).to receive(:key).and_return('F957nHNpAp3Ja9cQ3IEEbvhryjoaFr6T')
  end

  let!(:active_whitelabel_mission) { create(:mission, whitelabel: true, whitelabel_domain: 'example.org', whitelabel_api_public_key: build(:api_public_key), whitelabel_api_key: build(:api_key)) }
  let!(:blockchain_transaction) { create(:static_blockchain_transaction, id: 11111111) }
  let!(:project) { blockchain_transaction.blockchain_transactable.project }
  let(:verified_account) { create :account, verifications: [build(:verification, provider: nil)] }

  before do
    header 'API-Key', build(:api_key)
    project.update(mission: active_whitelabel_mission)
  end

  explanation 'Generate blockchain transactions for project to process and submit to blockchain.'

  header 'Content-Type', 'application/json'

  post '/api/v1/projects/:project_id/blockchain_transactions' do
    with_options with_example: true do
      parameter :project_id, 'project id', required: true, type: :integer
    end

    with_options with_example: true do
      response_field :id, 'transaction id', type: :integer
      response_field :blockchain_transactable_id, 'transactable id', type: :integer
      response_field :amount, 'transaction amount', type: :string
      response_field :destination, 'transaction destination', type: :string
      response_field :source, 'transaction source', type: :string
      response_field :nonce, 'transaction nonce', type: :string
      response_field :contract_address, 'token contract address', type: :string
      response_field :network, 'token network', type: :string
      response_field :tx_hash, 'transaction hash', type: :string
      response_field :tx_raw, 'transaction in HEX', type: :string
      response_field :status, 'transaction status (created pending cancelled succeed failed)', type: :string
      response_field :status_message, 'transaction status message', type: :string
      response_field :createdAt, 'transaction creation timestamp', type: :string
      response_field :updatedAt, 'transaction update timestamp', type: :string
    end

    with_options scope: :transaction, with_example: true do
      parameter :source, 'transaction source wallet address', required: true, type: :string
      parameter :nonce, 'transaction nonce', required: true, type: :string
    end

    with_options with_example: true do
      parameter :blockchain_transactable_type, 'transactable type to generate transaction for (awards, transfer_rules, account_token_records)', required: false, type: :string
      parameter :blockchain_transactable_id, 'transactable id of transactable type to generate transaction for', required: false, type: :string
    end

    context '201' do
      let!(:project_id) { project.id }
      let!(:award) { create(:award, status: :accepted, award_type: create(:award_type, project: project), account: verified_account) }
      let!(:wallet) { create(:wallet, account: award.account, _blockchain: project.token._blockchain, address: build(:ethereum_address_1)) }

      let!(:transaction) do
        {
          source: build(:ethereum_address_1),
          nonce: 1
        }
      end

      example 'GENERATE TRANSACTION' do
        explanation 'Generates a new blockchain transaction for a transactable and locks the transactable for 10 minutes'

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST', 'example.org')

        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')

        VCR.use_cassette("infura/#{project.token._blockchain}/#{project.token.contract_address}/contract_init") do
          do_request(request)
        end

        expect(status).to eq(201)
      end

      example 'GENERATE TRANSACTION – WITH PROJECT TRANSACTION API KEY' do
        explanation 'Generates a new blockchain transaction for a transactable and locks the transactable for 10 minutes'

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST', 'example.org')

        project.regenerate_api_key
        header 'API-Key', nil
        header 'API-Transaction-Key', project.api_key.key

        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')

        VCR.use_cassette("infura/#{project.token.ethereum_network}/#{project.token.ethereum_contract_address}/contract_init") do
          do_request(request)
        end

        expect(status).to eq(201)
      end

      example 'GENERATE TRANSACTION – TRANSACTABLE TYPE' do
        explanation 'Generates a new blockchain transaction for transactable with supplied type and locks the transactable for 10 minutes'
        create(:static_transfer_rule, id: 11111112, token: project.token)

        request = build(:api_signed_request, { transaction: transaction, blockchain_transactable_type: 'transfer_rules' }, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST', 'example.org')

        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')
        allow_any_instance_of(RegGroup).to receive(:blockchain_id).and_return(1001)
        VCR.use_cassette("infura/#{project.token._blockchain}/#{project.token.contract_address}/contract_init") do
          do_request(request)
        end
        expect(status).to eq(201)
      end

      example 'GENERATE TRANSACTION – TRANSACTABLE TYPE AND TRANSACTABLE ID' do
        explanation 'Generates a new blockchain transaction for transactable with supplied type and id and locks the transactable for 10 minutes'
        t = create(:static_transfer_rule, id: 11111113, token: project.token)

        request = build(:api_signed_request, { transaction: transaction, blockchain_transactable_type: 'transfer_rules', blockchain_transactable_id: t.id }, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST', 'example.org')

        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')
        allow_any_instance_of(RegGroup).to receive(:blockchain_id).and_return(1001)

        VCR.use_cassette("infura/#{project.token._blockchain}/#{project.token.contract_address}/contract_init") do
          do_request(request)
        end

        expect(status).to eq(201)
      end
    end

    context '204' do
      let!(:project_id) { project.id }

      let!(:transaction) do
        {
          source: build(:ethereum_address_1),
          nonce: 1
        }
      end

      example 'GENERATE TRANSACTION - NO TRANSFERS' do
        explanation 'Returns empty response if no transactables available for transaction'

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transactions_path(project_id: project.id), 'POST', 'example.org')
        do_request(request)
        expect(status).to eq(204)
      end
    end
  end

  put '/api/v1/projects/:project_id/blockchain_transactions/:id' do
    with_options with_example: true do
      parameter :project_id, 'project id', required: true, type: :integer
      parameter :id, 'transaction id', required: true, type: :integer
    end

    with_options scope: :transaction, with_example: true do
      parameter :tx_hash, 'transaction hash', required: true, type: :string
    end

    context '200', vcr: true do
      let!(:project_id) { project.id }
      let!(:id) { blockchain_transaction.id }

      let!(:transaction) do
        {
          tx_hash: '0x5d372aec64aab2fc031b58a872fb6c5e11006c5eb703ef1dd38b4bcac2a9977d'
        }
      end

      example 'SUBMIT TRANSACTION' do
        explanation 'Marks transaction as pending and returns transaction details, see GENERATE TRANSACTION for response fields'

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'PUT', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end

  delete '/api/v1/projects/:project_id/blockchain_transactions/:id' do
    with_options with_example: true do
      parameter :project_id, 'project id', required: true, type: :integer
      parameter :id, 'transaction id', required: true, type: :integer
    end

    with_options scope: :transaction, with_example: true do
      parameter :tx_hash, 'transaction hash', required: true, type: :string
      parameter :status_message, 'transaction status message', type: :string
      parameter :failed, 'marks transaction as failed, to exclude the transactable from further transactions', type: :string
      parameter :switch_hot_wallet_to_manual_mode, 'switch hot wallet to manual mode', type: :string
    end

    context '200', vcr: true do
      let!(:project_id) { project.id }
      let!(:id) { blockchain_transaction.id }

      let!(:transaction) do
        {
          tx_hash: blockchain_transaction.tx_hash,
          status_message: 'hot wallet error: insufficient balance'
        }
      end

      example 'CANCEL TRANSACTION' do
        explanation 'Marks transaction as cancelled and releases transfer for a new transaction, see GENERATE TRANSACTION for response fields'
        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end

    context '200', vcr: true do
      let!(:project_id) { project.id }
      let!(:id) { blockchain_transaction.id }

      let!(:transaction) do
        {
          tx_hash: blockchain_transaction.tx_hash,
          status_message: 'hot wallet error: unprocessable tx',
          failed: 'true',
          switch_hot_wallet_to_manual_mode: 'true'
        }
      end

      example 'FAIL TRANSACTION AND SWITCH HOT WALLET MODE TO MANUAL' do
        explanation 'Marks transaction as failed and excludes transfer from further transactions and switch hot wallet mode to manual. ' \
                    'See GENERATE TRANSACTION for response fields.'

        allow_any_instance_of(BlockchainTransaction).to receive(:id).and_return('40')

        request = build(:api_signed_request, { transaction: transaction }, api_v1_project_blockchain_transaction_path(project_id: project.id, id: blockchain_transaction.id), 'DELETE', 'example.org')
        do_request(request)
        expect(status).to eq(200)
      end
    end
  end
end
