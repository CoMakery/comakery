require 'webmock/rspec'
include WebMock::API

WebMock.enable!

# TODO: Replace Mom factory with FactoryBot factories.

class Mom
  def account(**attrs)
    defaults = {
      email: "me+#{SecureRandom.hex(20)}@example.com",
      first_name: 'Eva',
      last_name: 'Smith',
      nickname: "hunter-#{SecureRandom.hex(20)}",
      date_of_birth: '1990/01/01',
      country: 'United States of America',
      specialty: Specialty.find_or_create_by(name: 'General'),
      password: valid_password,
      verifications: [Verification.new(passed: true, provider: nil, max_investment_usd: 100000)]
    }

    if attrs[:unverified]
      defaults.delete(:verifications)
      attrs.delete(:unverified)
    end

    Account.new(defaults.merge(attrs))
  end

  def static_account(**attrs)
    defaults = {
      email: 'me+cc4b6d000417106d1cbbb357ebadd3a0560718bb@example.com',
      first_name: 'Eva',
      last_name: 'Smith',
      nickname: 'hunter-0cc45156d229f0a44c938ae649dedb8c1e0ca1de',
      date_of_birth: '1990/01/01',
      country: 'United States of America',
      specialty: Specialty.find_or_create_by(name: 'General'),
      password: valid_password,
      managed_account_id: '1c182a7b-4f22-4636-9047-8bab32352949',
      verifications: [Verification.new(passed: true, provider: nil, max_investment_usd: 100000)]
    }
    Account.new(defaults.merge(attrs))
  end

  def wallet(**attrs)
    defaults = {
      name: 'Wallet',
      _blockchain: :bitcoin,
      account: create(:account),
      address: bitcoin_address_1
    }
    Wallet.new(defaults.merge(attrs))
  end

  def eth_wallet(**attrs)
    defaults = {
      name: 'Wallet',
      _blockchain: :ethereum_ropsten,
      account: create(:account),
      address: ethereum_address_1
    }
    Wallet.new(defaults.merge(attrs))
  end

  def ore_id_wallet(**attrs)
    defaults = {
      source: :ore_id,
      ore_id_account: build(:ore_id, skip_jobs: true),
      _blockchain: 'algorand_test',
      address: build(:algorand_address_1)
    }
    build(:wallet, defaults.merge(attrs))
  end

  def balance(**attrs)
    defaults = {
      wallet: create(:wallet),
      token: create(:token)
    }
    Balance.new(defaults.merge(attrs))
  end

  def ore_id(**attrs)
    defaults = {
      account: create(:account),
      account_name: 'ore1ryuzfqwy'
    }

    o = nil
    a = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline unless attrs.key?(:skip_jobs)
    attrs.delete(:skip_jobs)

    VCR.use_cassette("ore_id_service/#{attrs.fetch(:account_name, defaults[:account_name])}", match_requests_on: %i[method uri]) do
      o = OreIdAccount.create!(defaults.merge(attrs))
    end

    ActiveJob::Base.queue_adapter = a
    o
  end

  def specialty(**attrs)
    defaults = {
      name: "Specialty #{SecureRandom.hex(20)}"
    }
    Specialty.new(defaults.merge(attrs))
  end

  def experience(**attrs)
    defaults = {
      specialty: create(:specialty),
      account: create(:account),
      level: 1
    }
    Experience.new(defaults.merge(attrs))
  end

  def verification(**attrs)
    defaults = {
      account: create(:account),
      provider: create(:account),
      passed: true,
      max_investment_usd: 1000000
    }
    Verification.new(defaults.merge(attrs))
  end

  def reg_group(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)

    defaults = {
      token: token,
      name: "RegGroup #{SecureRandom.hex(20)}",
      blockchain_id: RegGroup.maximum(:id).to_i + SecureRandom.hex(20).to_i(16)
    }
    RegGroup.new(defaults.merge(attrs))
  end

  def transfer_type(**attrs)
    project = attrs[:project] || create(:project)

    defaults = {
      project: project,
      name: "Type #{SecureRandom.hex(5)}"
    }
    TransferType.new(defaults.merge(attrs))
  end

  def transfer_rule(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)

    defaults = {
      token: token,
      sending_group: create(:reg_group, token: token),
      receiving_group: create(:reg_group, token: token),
      lockup_until: 1.day.ago
    }
    TransferRule.new(defaults.merge(attrs))
  end

  def static_transfer_rule(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token, id: 60)

    defaults = {
      token: token,
      sending_group: create(:reg_group, id: 50, token: token),
      receiving_group: create(:reg_group, id: 51, token: token),
      lockup_until: 1.day.ago
    }
    TransferRule.new(defaults.merge(attrs))
  end

  def account_token_record(**attrs) # rubocop:todo Metrics/CyclomaticComplexity
    token = attrs[:token] || build(:comakery_dummy_token)
    account = attrs[:account] || create(:account)
    reg_group = attrs[:reg_group] || create(:reg_group, token: token)
    wallet =
      if attrs.key?(:wallet)
        attrs[:wallet]
      elsif (account_wallet = account.wallets.find_by(_blockchain: token._blockchain))
        account_wallet
      else
        create(
          :wallet,
          account: account,
          _blockchain: token._blockchain,
          address: attrs[:address] || build(:ethereum_address_2)
        )
      end

    attrs.except!(:address, :account, :reg_group, :wallet)

    defaults = {
      account: account,
      token: token,
      wallet: wallet,
      reg_group: reg_group,
      max_balance: 100000,
      balance: 200,
      account_frozen: false,
      lockup_until: 1.day.ago
    }

    AccountTokenRecord.new(defaults.merge(attrs))
  end

  def static_account_token_record(**attrs)
    token = build(:comakery_dummy_token, id: 90)
    account = create(:static_account, id: 70)
    reg_group = attrs[:reg_group] || create(:reg_group, id: 100, token: token)
    wallet =
      if (account_wallet = account.wallets.find_by(_blockchain: token._blockchain))
        account_wallet
      else
        create(:wallet, id: 90, account: account, _blockchain: token._blockchain, address: build(:ethereum_address_2))
      end

    attrs.except!(:address, :account, :reg_group, :wallet)

    defaults = {
      account: account,
      token: token,
      wallet: wallet,
      reg_group: reg_group,
      max_balance: 100000,
      balance: 200,
      account_frozen: false,
      lockup_until: 1.day.ago
    }

    AccountTokenRecord.new(defaults.merge(attrs))
  end

  def blockchain_transaction(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)
    attrs.delete(:token)

    award = blockchain_transaction__award(attrs.merge(token: token))
    attrs.delete(:award)

    defaults = {
      blockchain_transactables: award,
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransaction.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_lockup(**attrs)
    token = attrs[:token] || create(:lockup_token)
    attrs.delete(:token)

    award = blockchain_transaction__lockup_award(attrs.merge(token: token))
    attrs.delete(:award)

    defaults = {
      blockchain_transactables: award,
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransaction.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_lockup_batch(**attrs)
    token = attrs[:token] || create(:lockup_token)
    attrs.delete(:token)

    award1 = blockchain_transaction__lockup_award(attrs.merge(token: token))
    award2 = award1.clone_on_assignment
    attrs.delete(:award)

    defaults = {
      blockchain_transactables: Award.where(id: [award1.id, award2.id]),
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransaction.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_award_batch(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token, batch_contract_address: '0x0')
    attrs.delete(:token)

    award1 = blockchain_transaction__award(attrs.merge(token: token))
    award2 = award1.clone_on_assignment
    attrs.delete(:award)

    defaults = {
      blockchain_transactables: Award.where(id: [award1.id, award2.id]),
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransaction.create!(defaults.merge(attrs))
    end
  end

  def static_blockchain_transaction(**attrs)
    token = create(:comakery_dummy_token)
    hot_wallet = build(:wallet, account: nil, source: :hot_wallet, _blockchain: token._blockchain, address: build(:ethereum_address_1))
    project = create(:project, id: 45, token: token, hot_wallet: hot_wallet, hot_wallet_mode: :auto_sending)
    account = create(:account)

    account.wallets.find_by(_blockchain: project.token._blockchain) || create(
      :wallet,
      account: account,
      _blockchain: project.token._blockchain,
      address: build(:ethereum_address_2)
    )

    award = create(:award, id: 50, amount: 1,
                           status: :accepted,
                           account: account,
                           award_type: create(
                             :award_type,
                             project: project
                           ),
                           transfer_type: create(
                             :transfer_type,
                             project: project
                           ))
    defaults = {
      blockchain_transactables: award,
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: 1,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransaction.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_transfer_rule(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)
    attrs.delete(:token)

    defaults = {
      blockchain_transactables: create(:transfer_rule),
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransactionTransferRule.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_pause(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)
    attrs.delete(:token)

    defaults = {
      blockchain_transactables: token,
      status: :created
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransactionTokenFreeze.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_unpause(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)
    attrs.delete(:token)
    token.update(token_frozen: true)

    defaults = {
      blockchain_transactables: token,
      status: :created
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransactionTokenUnfreeze.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_opt_in(**attrs)
    defaults = {
      blockchain_transactables: create(:token_opt_in),
      status: :created
    }

    VCR.use_cassette('algorand_test/status') do
      BlockchainTransactionOptIn.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_token_freeze(**attrs)
    defaults = {
      blockchain_transactables: create(:algo_sec_token),
      status: :created
    }

    VCR.use_cassette('algorand_test/status') do
      BlockchainTransactionTokenFreeze.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_token_unfreeze(**attrs)
    defaults = {
      blockchain_transactables: create(:algo_sec_token),
      status: :created
    }

    VCR.use_cassette('algorand_test/status') do
      BlockchainTransactionTokenUnfreeze.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_account_token_record(**attrs)
    token = attrs[:token] || create(:comakery_dummy_token)
    attrs.delete(:token)

    defaults = {
      blockchain_transactables: create(:account_token_record),
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    VCR.use_cassette("infura/#{token._blockchain}/#{token.contract_address}/contract_init") do
      BlockchainTransactionAccountTokenRecord.create!(defaults.merge(attrs))
    end
  end

  def blockchain_transaction_account_token_record_algo(**attrs)
    token = attrs[:token] || create(:algo_sec_token)
    attrs.delete(:token)

    defaults = {
      blockchain_transactables: create(:account_token_record, token: token, address: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU'),
      amount: 1,
      source: build(:ethereum_address_1),
      nonce: token._token_type_token? ? rand(1_000_000) : nil,
      status: :created,
      status_message: 'dummy'
    }

    BlockchainTransactionAccountTokenRecord.create!(defaults.merge(attrs))
  end

  def blockchain_transaction__lockup_award(**attrs) # rubocop:todo Metrics/CyclomaticComplexity
    project = attrs[:award]&.project || create(
      :project,
      token: attrs[:token]
    )

    account = attrs[:account] || create(
      :account
    )

    account.wallets.find_by(_blockchain: project.token._blockchain) || create(
      :wallet,
      account: account,
      _blockchain: project.token._blockchain,
      address: attrs[:destination] || build(:ethereum_address_2)
    )

    attrs[:award] || create(
      :award,
      amount: attrs[:amount] || 1,
      status: :accepted,
      account: account,
      commencement_date: Time.current,
      lockup_schedule_id: 0,
      award_type: create(
        :award_type,
        project: project
      ),
      transfer_type: create(
        :transfer_type,
        project: project
      )
    )
  end

  def blockchain_transaction__award(**attrs) # rubocop:todo Metrics/CyclomaticComplexity
    project = attrs[:award]&.project || create(
      :project,
      token: attrs[:token]
    )

    account = attrs[:account] || create(
      :account
    )

    account.wallets.find_by(_blockchain: project.token._blockchain) || create(
      :wallet,
      account: account,
      _blockchain: project.token._blockchain,
      address: attrs[:destination] || build(:ethereum_address_2)
    )

    attrs[:award] || create(
      :award,
      amount: attrs[:amount] || 1,
      status: :accepted,
      account: account,
      award_type: create(
        :award_type,
        project: project
      ),
      transfer_type: create(
        :transfer_type,
        project: project
      )
    )
  end

  def blockchain_transaction_dag(**attrs)
    token = attrs[:token] || create(:dag_token)
    attrs.delete(:token)

    award = blockchain_transaction__award_dag(attrs.merge(token: token))
    attrs.delete(:award)

    defaults = {
      blockchain_transactables: award,
      amount: 1,
      source: build(:constellation_address_1),
      nonce: nil,
      status: :created,
      status_message: 'dummy'
    }

    BlockchainTransaction.create!(defaults.merge(attrs))
  end

  def blockchain_transaction__award_dag(**attrs) # rubocop:todo Metrics/CyclomaticComplexity
    project = attrs[:award]&.project || create(
      :project,
      token: attrs[:token]
    )

    account = attrs[:account] || create(
      :account
    )

    account.wallets.find_by(_blockchain: project.token._blockchain) || create(
      :wallet,
      account: account,
      _blockchain: project.token._blockchain,
      address: attrs[:destination] || build(:constellation_address_2)
    )

    attrs[:award] || create(
      :award,
      amount: attrs[:amount] || 1,
      status: :accepted,
      account: account,
      award_type: create(
        :award_type,
        project: project
      ),
      transfer_type: create(
        :transfer_type,
        project: project
      )
    )
  end

  def blockchain_transaction_update(**attrs)
    defaults = {
      blockchain_transaction: create(:blockchain_transaction),
      status: :created,
      status_message: 'dummy'
    }

    BlockchainTransactionUpdate.new(defaults.merge(attrs))
  end

  def account_with_auth(**attrs)
    account(**attrs).tap { |a| create(:authentication, account: a) }
  end

  def cc_authentication(**attrs)
    defaults = {}
    defaults[:account] = account unless attrs.key?(:account)
    authentication(defaults.merge(attrs))
  end

  def sb_authentication(**attrs)
    defaults = {}
    defaults[:account] = account unless attrs.key?(:account)
    authentication(defaults.merge(attrs))
  end

  def authentication(**attrs)
    @@authentication_count ||= 0 # rubocop:todo Style/ClassVars
    @@authentication_count += 1 # rubocop:todo Style/ClassVars
    defaults = {
      provider: 'slack',
      token: 'slack token',
      uid: "slack user id #{@@authentication_count}"
    }
    defaults[:account] = create(:account, first_name: 'John', last_name: 'Doe') unless attrs.key?(:account)
    Authentication.new(defaults.merge(attrs))
  end

  def cc_project(account = create(:cc_authentication).account, **attrs)
    project(account, { title: 'Citizen Code', token: create(:token) }.merge(**attrs))
  end

  def sb_project(account = create(:account), **attrs)
    project(account, { title: 'Swarmbot', payment_type: 'project_token', token: create(:token) }.merge(**attrs))
  end

  def project(account = create(:account_with_auth), **attrs)
    defaults = {
      title: 'Uber for Cats',
      description: 'We are going to build amazing',
      tracker: 'https://github.com/example/uber_for_cats',
      account: account,
      legal_project_owner: 'UberCatz Inc',
      require_confidentiality: false,
      exclusive_contributions: false,
      visibility: 'member',
      long_id: SecureRandom.hex(20),
      maximum_tokens: 1_000_000_000_000_000_000,
      token: create(:token),
      mission: create(:mission),
      square_image: dummy_image,
      panoramic_image: dummy_image
    }
    Project.new(defaults.merge(attrs))
  end

  def static_project(account = create(:account_with_auth), **attrs)
    defaults = {
      title: 'Uber for Cats',
      description: 'We are going to build amazing',
      tracker: 'https://github.com/example/uber_for_cats',
      account: account,
      legal_project_owner: 'UberCatz Inc',
      require_confidentiality: false,
      exclusive_contributions: false,
      visibility: 'member',
      long_id: SecureRandom.hex(20),
      maximum_tokens: 1_000_000_000_000_000_000,
      token: create(:token),
      mission: create(:mission)
    }
    Project.new(defaults.merge(attrs))
  end

  def token(**attrs)
    defaults = {
      name: "Token-#{SecureRandom.hex(20)}",
      symbol: "TKN#{SecureRandom.hex(20)}",
      logo_image: dummy_image,
      token_frozen: false
    }

    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def static_token(**attrs)
    defaults = {
      name: 'Token-479f48b87576885bc6c499e373d3a5094e1600bc',
      symbol: 'TKN7b9d835bc7eab2acde5e892b447cd2b83b6788fd',
      token_frozen: false
    }

    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def erc20_token(**attrs)
    defaults = {
      name: "erc20-#{SecureRandom.hex(20)}",
      symbol: "XYZ#{SecureRandom.hex(20)}",
      logo_image: dummy_image,
      _token_type: :erc20,
      decimal_places: 18,
      _blockchain: :ethereum_ropsten,
      contract_address: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
      token_frozen: false
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def comakery_token(**attrs)
    defaults = {
      name: "ComakeryToken-#{SecureRandom.hex(20)}",
      symbol: "XYZ#{SecureRandom.hex(20)}",
      logo_image: dummy_image,
      _token_type: :comakery_security_token,
      decimal_places: 18,
      _blockchain: :ethereum_ropsten,
      contract_address: '0x1D1592c28FFF3d3E71b1d29E31147846026A0a37',
      token_frozen: false
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def static_comakery_token(**attrs)
    defaults = {
      name: 'ComakeryToken-4d38e48b6c32993893db2b4a1f9e1162361762a6',
      symbol: 'XYZ90a27bfa779972c98a07b6b67567de4bd4a32bb5',
      _token_type: :comakery_security_token,
      decimal_places: 18,
      _blockchain: :ethereum_ropsten,
      contract_address: '0x1D1592c28FFF3d3E71b1d29E31147846026A0a37',
      token_frozen: false
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def comakery_dummy_token(**attrs)
    defaults = {
      name: "ComakeryDummyToken-#{SecureRandom.hex(20)}",
      symbol: "DUM#{SecureRandom.hex(20)}",
      logo_image: dummy_image,
      _blockchain: :ethereum_ropsten,
      contract_address: '0x1D1592c28FFF3d3E71b1d29E31147846026A0a37',
      _token_type: :comakery_security_token,
      decimal_places: 0,
      token_frozen: false
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def lockup_token(**attrs)
    defaults = {
      name: "LockupToken-#{SecureRandom.hex(20)}",
      symbol: "DUM#{SecureRandom.hex(20)}",
      logo_image: dummy_image,
      _blockchain: :ethereum_rinkeby,
      contract_address: '0x9608848FA0063063d2Bb401e8B5efFcb8152Ec65',
      _token_type: :token_release_schedule,
      decimal_places: 10,
      token_frozen: false
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def dag_token(**attrs)
    defaults = {
      logo_image: dummy_image,
      _token_type: :dag,
      _blockchain: :constellation_test
    }
    t = Token.new(defaults.merge(attrs))

    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end

    t
  end

  def algorand_token(**attrs)
    defaults = {
      name: "Algorand-#{SecureRandom.hex(20)}",
      symbol: 'ALGO',
      logo_image: dummy_image,
      token_frozen: false,
      _blockchain: 'algorand_test',
      _token_type: 'algo'
    }

    Token.create!(defaults.merge(attrs))
  end

  def asa_token(**attrs)
    defaults = {
      name: "Asa-#{SecureRandom.hex(20)}",
      symbol: "TKN-#{SecureRandom.hex(20)}",
      contract_address: attrs[:contract_address] || '13076367',
      logo_image: dummy_image,
      token_frozen: false,
      _blockchain: 'algorand_test',
      _token_type: 'asa'
    }

    t = Token.new(defaults.merge(attrs))
    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end
    t
  end

  def algo_sec_token(**attrs)
    defaults = {
      name: "Asa-#{SecureRandom.hex(20)}",
      symbol: "TKN-#{SecureRandom.hex(20)}",
      contract_address: attrs[:contract_address] || '13258116',
      decimal_places: 8,
      logo_image: dummy_image,
      token_frozen: false,
      _blockchain: 'algorand_test',
      _token_type: 'algorand_security_token'
    }

    t = Token.new(defaults.merge(attrs))
    VCR.use_cassette("#{t.blockchain.explorer_api_host}/contract/#{t.contract_address}/token_init") do
      t.save!
    end
    t
  end

  def interest(**attrs)
    params = {
      protocol: 'Moms protocol',
      account: create(:account),
      project: create(:project),
      specialty: create(:specialty)
    }.merge(attrs)

    Interest.new(params)
  end

  def project_role(**attrs)
    params = {
      account: create(:account),
      project: create(:project)
    }.merge(attrs)

    ProjectRole.new(params)
  end

  def channel(**attrs)
    defaults = {
      team: create(:team),
      project: create(:project),
      channel_id: SecureRandom.hex(5),
      name: 'general'
    }
    Channel.new defaults.merge(attrs)
  end

  def award_type(**attrs)
    defaults = {
      name: 'Contribution',
      goal: 'none',
      description: 'none',
      state: 'public'
    }
    attrs[:project] = create(:project) unless attrs[:project]
    AwardType.new(defaults.merge(attrs))
  end

  def award_ready(**attrs)
    params = {
      name: 'none',
      description: 'none',
      why: 'none',
      requirements: 'none',
      proof_link: 'http://nil',
      amount: 50
    }.merge(attrs)

    params[:award_type] ||= create(:award_type)
    params[:issuer] ||= create(:account)
    params[:account] ||= create(:account)
    params[:transfer_type] ||= create(:transfer_type, project: params[:award_type].project)

    Award.new(params)
  end

  def project_with_ready_task(**attrs)
    params = {
      name: 'none',
      description: 'none',
      why: 'none',
      requirements: 'none',
      amount: 50
    }.merge(attrs)

    params[:project] ||= create(:project, account: create(:account))
    project = params.delete(:project)
    params[:issuer] ||= create(:account)
    params[:award_type] ||= create(:award_type, project: project)
    params[:transfer_type] ||= create(:transfer_type, project: params[:award_type].project)

    award = Award.new(params)
    award.save!
    project
  end

  def award(**attrs)
    params = {
      name: 'none',
      description: 'none',
      why: 'none',
      requirements: 'none',
      proof_link: 'http://nil',
      proof_id: 'abc123',
      status: 'accepted',
      message: 'Great work',
      quantity: 1,
      amount: 50,
      submission_url: 'http://dummy',
      submission_comment: 'comment',
      issuer: create(:account)
    }.merge(attrs)

    params[:award_type] ||= create(:award_type, project: create(:project, account: params[:issuer]))
    params[:account] ||= params[:email] ? nil : create(:account)
    params[:transfer_type] ||= create(:transfer_type, project: params[:award_type].project)

    Award.new(params)
  end

  def transfer(**attrs)
    params = {
      name: 'Bought',
      source: :bought,
      description: 'Investment',
      why: '–',
      requirements: '–',
      status: :accepted,
      quantity: 1,
      amount: 50,
      issuer: create(:account),
      account: create(:account)
    }.merge(attrs)

    params[:award_type] ||= create(:project, account: params[:issuer]).default_award_type
    params[:transfer_type] ||= create(:transfer_type, project: params[:award_type].project)

    Award.new(params)
  end

  def slack(authentication = create(:authentication))
    Comakery::Slack.new(authentication)
  end

  def team(**attrs)
    defaults = {
      team_id: SecureRandom.hex(5),
      name: "Team-#{SecureRandom.hex(2)}",
      provider: 'slack',
      domain: "test-app-#{SecureRandom.hex(2)}"
    }
    Team.new(defaults.merge(attrs))
  end

  def valid_password
    'a password'
  end

  def mission(**attrs)
    defaults = {
      name: 'test1',
      subtitle: 'test1',
      description: 'test1',
      image: dummy_image,
      logo: dummy_image,
      require_invitation: false
    }
    Mission.new(defaults.merge(attrs))
  end

  def whitelabel_mission(**attrs)
    whitelabel_domain = attrs.key?(:whitelabel_domain) ? attrs[:whitelabel_domain] : 'wl.test.host'

    create(
      :mission,
      whitelabel: true,
      whitelabel_domain: whitelabel_domain,
      whitelabel_logo: dummy_image,
      whitelabel_logo_dark: dummy_image,
      whitelabel_favicon: dummy_image,
      whitelabel_api_public_key: build(:api_public_key),
      whitelabel_api_key: build(:api_key),
      require_invitation: attrs[:require_invitation] ? true : false,
      project_awards_visible: attrs.fetch(:project_awards_visible, false)
    )
  end

  def active_whitelabel_mission
    create(:whitelabel_mission, whitelabel_domain: 'test.host')
  end

  def api_public_key
    'O7zTH4xHnD1jRKheBTrpNN24Fg1ddL8DHKi/zgVCVpA='
  end

  def api_private_key
    'eodjQfDLTyNCBnz+MORHW0lOKWZnCTyPDTFcwAdVRyQ7vNMfjEecPWNEqF4FOuk03bgWDV10vwMcqL/OBUJWkA=='
  end

  def api_key
    '28ieQrVqi5ZQXd77y+pgiuJGLsFfwkWO'
  end

  def api_signed_request(data, path, method, host = 'test.host')
    Comakery::APISignature.new('body' => {
      'data' => data.is_a?(Hash) ? data.deep_stringify_keys : data,
      'url' => "http://#{host}#{path}",
      'method' => method
    }).sign(build(:api_private_key))
  end

  def ethereum_address_1
    '0x42D00fC2Efdace4859187DE4865Df9BaA320D5dB'
  end

  def ethereum_address_2
    '0xB4252b39f8506A711205B0b1C4170f0034065b46'
  end

  def ethereum_contract_address
    '0x1D1592c28FFF3d3E71b1d29E31147846026A0a37'
  end

  def algorand_address_1
    'YFGM3UODOZVHSI4HXKPXOKFI6T2YCIK3HKWJYXYFQBONJD4D3HD2DPMYW4'
  end

  def algorand_address_2
    'E3IT2TDWEJS55XCI5NOB2HON6XUBIZ6SDT2TAHTKDQMKR4AHEQCROOXFIE'
  end

  def eth_client(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'

    Comakery::Eth.new(
      host
    )
  end

  def eth_tx(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x5d372aec64aab2fc031b58a872fb6c5e11006c5eb703ef1dd38b4bcac2a9977d'
    tx = attrs[:blockchain_transaction] || create(
      :blockchain_transaction,
      source: '0x66ebd5cdf54743a6164b0138330f74dce436d842',
      destination: '0x1d1592c28fff3d3e71b1d29e31147846026a0a37',
      amount: 0,
      current_block: 1
    )

    # From:
    # 0x66ebd5cdf54743a6164b0138330f74dce436d842
    # Contract:
    # 0x1d1592c28fff3d3e71b1d29e31147846026a0a37
    # To:
    # 0x8599d17ac1cec71ca30264ddfaaca83c334f8451
    # Amount:
    # 100

    Comakery::Eth::Tx.new(
      host,
      hash,
      tx
    )
  end

  def erc20_transfer(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x5d372aec64aab2fc031b58a872fb6c5e11006c5eb703ef1dd38b4bcac2a9977d'
    tx = attrs[:blockchain_transaction] || create(
      :blockchain_transaction,
      source: '0x66ebd5cdf54743a6164b0138330f74dce436d842',
      destination: '0x8599d17ac1cec71ca30264ddfaaca83c334f8451',
      amount: 100,
      current_block: 1
    )

    # From:
    # 0x66ebd5cdf54743a6164b0138330f74dce436d842
    # Contract:
    # 0x1d1592c28fff3d3e71b1d29e31147846026a0a37
    # To:
    # 0x8599d17ac1cec71ca30264ddfaaca83c334f8451
    # Amount:
    # 100

    Comakery::Eth::Tx::Erc20::Transfer.new(
      host,
      hash,
      tx
    )
  end

  def lockup_transfer(**attrs)
    host = attrs[:host] || 'rinkeby.infura.io'
    hash = attrs[:hash] || '0x662784478c471d87e724705bca422b5c600f9f47622f18ab05d202969b5d1000'
    tx = attrs[:blockchain_transaction] || create(
      :blockchain_transaction,
      source: '0xf4258b3415cab41fc9ce5f9b159ab21ede0501b1',
      destinations: %w[
        0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
      ],
      amount: 100000000000,
      amounts: [100000000000],
      commencement_dates: [0],
      lockup_schedule_ids: [0],
      current_block: 1,
      contract_address: '0x9608848fa0063063d2bb401e8b5effcb8152ec65'
    )

    # From:
    # 0xf4258b3415cab41fc9ce5f9b159ab21ede0501b1
    # Contract:
    # 0x9608848fa0063063d2bb401e8b5effcb8152ec65
    # To:
    # 0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
    # Amount:
    # 100000000000
    # commencementTimestamps:
    # 0
    # scheduleIds
    # 0

    Comakery::Eth::Tx::Erc20::ScheduledToken::FundReleaseSchedule.new(
      host,
      hash,
      tx
    )
  end

  def lockup_batch_transfer(**attrs)
    host = attrs[:host] || 'rinkeby.infura.io'
    hash = attrs[:hash] || '0xf72a70bb1393bab0fba012d32e836d9250c01756a9685f2ef1355976962ec9d5'
    tx = attrs[:blockchain_transaction] || create(
      :blockchain_transaction,
      source: '0xf4258b3415cab41fc9ce5f9b159ab21ede0501b1',
      destinations: %w[
        0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
        0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
      ],
      amounts: [100000000000, 100000000000],
      commencement_dates: [0, 0],
      lockup_schedule_ids: [0, 0],
      current_block: 1,
      contract_address: '0x9608848fa0063063d2bb401e8b5effcb8152ec65'
    )

    # From:
    # 0xf4258b3415cab41fc9ce5f9b159ab21ede0501b1
    # Contract:
    # 0x9608848fa0063063d2bb401e8b5effcb8152ec65
    # To:
    # 0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
    # 0xF4258B3415Cab41Fc9cE5f9b159Ab21ede0501B1
    # Amount:
    # 100000000000
    # 100000000000
    # commencementTimestamps:
    # 0
    # 0
    # scheduleIds
    # 0
    # 0

    Comakery::Eth::Tx::Erc20::ScheduledToken::BatchFundReleaseSchedule.new(
      host,
      hash,
      tx
    )
  end

  def erc20_batch_transfer(**attrs)
    host = attrs[:host] || 'rinkeby.infura.io'
    hash = attrs[:hash] || '0x0e566595a62c566a00b0ebdf80f8d812c0a8fd893dbd5198c8c139b223746b7d'
    tx = attrs[:blockchain_transaction] || create(
      :blockchain_transaction,
      source: '0x66ebd5cdf54743a6164b0138330f74dce436d842',
      destinations: %w[
        0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
        0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
        0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
      ],
      amounts: [1, 1, 1],
      current_block: 1
    )

    # From:
    # 0x15b4eda54e7aa56e4ca4fe6c19f7bf9d82eca2fc
    # Batch Contract:
    # 0x68ac9a329c688afbf1fc2e5d3e8cb6e88989e2cc
    # Contract:
    # 0xE322488096C36edccE397D179E7b1217353884BB
    # To:
    # 0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
    # 0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
    # 0x4735581201F4cAD63CCa0716AB4ac7D6d9CFB0ed
    # Amount:
    # 1
    # 1
    # 1

    Comakery::Eth::Tx::Erc20::BatchTransfer.new(
      host,
      hash,
      tx
    )
  end

  def erc20_mint(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x02286b586b53784715e7eda288744e1c14a5f2d691d43160d4e3c4d5f8825ad0'

    Comakery::Eth::Tx::Erc20::Mint.new(
      host,
      hash,
      attrs[:blockchain_transaction]
    )
  end

  def erc20_burn(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x1007e9116efab368169683b81ae576bd48e168bef2be1fea5ef096ccc9e5dcc0'

    Comakery::Eth::Tx::Erc20::Burn.new(
      host,
      hash,
      attrs[:blockchain_transaction]
    )
  end

  def security_token_set_allow_group_transfer(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0xdd2d8399654bf4b12308cacd013c63343fdd474eea902ff8738138a34c4ec582'

    # Inputs:
    # 0	from	uint256	0
    # 1	to	uint256	0
    # 2	lockedUntil	uint256	1586908800
    #
    # From:
    # 0x75f538eafdb14a2dc9f3909aa1e0ea19727ff44b

    Comakery::Eth::Tx::Erc20::SecurityToken::SetAllowGroupTransfer.new(
      host,
      hash,
      create(:blockchain_transaction_transfer_rule)
    )
  end

  def security_token_pause(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x60d8591313b2c675722db449e35d71b1cb90e4b57048a112e9b77cd2fa280e07'

    # From:
    # 0x29ac40ef5544f738187880fc6a2270a3303b7b3b

    Comakery::Eth::Tx::Erc20::SecurityToken::Pause.new(
      host,
      hash,
      create(:blockchain_transaction_pause)
    )
  end

  def security_token_unpause(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x96ac6711987f7f7ee69bd46abcbca13531389c5bb302d76aa2602c926dfbff4c'

    # From:
    # 0x29ac40ef5544f738187880fc6a2270a3303b7b3b

    Comakery::Eth::Tx::Erc20::SecurityToken::Unpause.new(
      host,
      hash,
      create(:blockchain_transaction_unpause)
    )
  end

  def security_token_set_address_permissions(**attrs)
    host = attrs[:host] || 'ropsten.infura.io'
    hash = attrs[:hash] || '0x9a5af207b43c656531363d46ed899bef73445e4a31cc65832df6ee7b9aad948d'

    # Inputs:
    # 0	addr	address	8599d17ac1cec71ca30264ddfaaca83c334f8451
    # 1	groupID	uint256	0
    # 2	timeLockUntil	uint256	86400
    # 3	maxBalance	uint256	100000000000000000000000000
    # 4	status	bool	false
    #
    # From:
    # 0x8599d17ac1cec71ca30264ddfaaca83c334f8451

    Comakery::Eth::Tx::Erc20::SecurityToken::SetAddressPermissions.new(
      host,
      hash,
      build(:blockchain_transaction_account_token_record)
    )
  end

  def erc20_contract(**attrs)
    token = create(
      :token,
      _token_type: :comakery_security_token,
      _blockchain: :ethereum_ropsten,
      contract_address: build(:ethereum_contract_address),
      symbol: 'DUM',
      decimal_places: 0
    )

    contract_address = attrs[:contract_address] || token.contract_address
    abi = attrs[:abi] || token.abi
    host = attrs[:host] || token.blockchain.explorer_api_host
    nonce = attrs[:nonce] || rand(1_000_000)

    VCR.use_cassette("#{host}/contract/#{contract_address}/contract_init") do
      Comakery::Eth::Contract::Erc20.new(
        contract_address,
        abi,
        host,
        nonce
      )
    end
  end

  def algo_sec_project_dummy_setup
    project = create(:project, token: create(:algo_sec_token, contract_address: '13997710'))
    admin_wallet = create(:wallet, _blockchain: project.token._blockchain, address: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA')
    contributor_wallet = create(:wallet, _blockchain: project.token._blockchain, address: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU')

    [project, admin_wallet.account, contributor_wallet.account]
  end

  def algo_sec_dummy_transfer(type: 'earned', amount: 0)
    project, admin, contributor = algo_sec_project_dummy_setup

    create(
      :transfer,
      issuer: admin,
      account: contributor,
      amount: amount,
      transfer_type: project.transfer_types.find_or_create_by(name: type),
      award_type: project.default_award_type
    )
  end

  def algo_sec_dummy_restrictions(reg_group: 1, max_balance: 100, frozen: false, lockup_until: 1)
    project, _admin, contributor = algo_sec_project_dummy_setup

    AccountTokenRecord.create(
      account: contributor,
      token: project.token,
      reg_group: RegGroup.find_or_create_by!(token_id: project.token.id, blockchain_id: reg_group),
      max_balance: max_balance,
      balance: 0,
      account_frozen: frozen,
      lockup_until: lockup_until
    )
  end

  def algo_sec_dummy_transfer_rule(from: 0, to: 0, lockup_until: 0)
    project, _admin, _contributor = algo_sec_project_dummy_setup
    gr_from = RegGroup.find_or_create_by!(token_id: project.token.id, blockchain_id: from)

    gr_to = if from == to
      gr_from
    else
      RegGroup.find_or_create_by!(token_id: project.token.id, blockchain_id: to)
    end

    TransferRule.new(
      token: project.token,
      sending_group: gr_from,
      receiving_group: gr_to,
      lockup_until: lockup_until
    )
  end

  def algorand_tx
    Comakery::Algorand::Tx.new(
      create(
        :blockchain_transaction,
        token: create(:algorand_token),
        amount: 9000000,
        tx_hash: 'MNGGXTRI4XE6LQJQ3AW3PBBGD5QQFRXMRSXZFUMHTKJKFEQ6TZ2A',
        source: 'YFGM3UODOZVHSI4HXKPXOKFI6T2YCIK3HKWJYXYFQBONJD4D3HD2DPMYW4',
        destination: 'E3IT2TDWEJS55XCI5NOB2HON6XUBIZ6SDT2TAHTKDQMKR4AHEQCROOXFIE'
      )
    )
  end

  def algorand_asset_opt_in_tx
    Comakery::Algorand::Tx::Asset::OptIn.new(
      create(
        :blockchain_transaction_opt_in,
        token: create(:asa_token, contract_address: '13076367'),
        amount: 0,
        tx_hash: 'D2SAP75JSXW3D43ZBHNLTJGASBCJDJIFLLQ5TQCZWMC33JHHQDPQ',
        source: 'YF6FALSXI4BRUFXBFHYVCOKFROAWBQZ42Y4BXUK7SDHTW7B27TEQB3AHSA',
        destination: 'E3IT2TDWEJS55XCI5NOB2HON6XUBIZ6SDT2TAHTKDQMKR4AHEQCROOXFIE'
      )
    )
  end

  def algorand_asset_tx
    Comakery::Algorand::Tx::Asset.new(
      create(
        :blockchain_transaction,
        token: create(:asa_token, contract_address: '13076367'),
        amount: 400,
        tx_hash: 'D2SAP75JSXW3D43ZBHNLTJGASBCJDJIFLLQ5TQCZWMC33JHHQDPQ',
        source: 'YF6FALSXI4BRUFXBFHYVCOKFROAWBQZ42Y4BXUK7SDHTW7B27TEQB3AHSA',
        destination: 'E3IT2TDWEJS55XCI5NOB2HON6XUBIZ6SDT2TAHTKDQMKR4AHEQCROOXFIE'
      )
    )
  end

  def algorand_app_tx
    Comakery::Algorand::Tx::App.new(
      create(
        :blockchain_transaction,
        token: create(:algo_sec_token, contract_address: '13997710'),
        amount: 0,
        tx_hash: 'UV7YMGF6ZQHHLGO63BSPLR5TFV4PYYMHPJDEUIDXMZNVVUCNLIRQ',
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU'
      )
    )
  end

  def algorand_app_opt_in_tx
    Comakery::Algorand::Tx::App::OptIn.new(
      create(
        :blockchain_transaction_opt_in,
        token: create(:algo_sec_token, contract_address: '13997710'),
        amount: 0,
        tx_hash: 'DHLXHTA6PZP222T6GKMXWYDZV5KIZXWJ4TTZ5AKL6SNWGCE3MH4A',
        source: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU'
      )
    )
  end

  def algorand_app_burn_tx
    tr = algo_sec_dummy_transfer(type: 'burn', amount: 30)

    Comakery::Algorand::Tx::App::SecurityToken::Burn.new(
      create(
        :blockchain_transaction,
        token: tr.token,
        blockchain_transactables: tr,
        amount: tr.total_amount,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        tx_hash: 'IR2UCCC4A7VDF65AJXMAIDSIINQCTNXIZAFC4GPSYY2HEZT7GB6Q'
      )
    )
  end

  def algorand_app_set_address_permissions_tx
    r = algo_sec_dummy_restrictions

    Comakery::Algorand::Tx::App::SecurityToken::SetAddressPermissions.new(
      create(
        :blockchain_transaction_account_token_record,
        token: r.token,
        blockchain_transactables: r,
        amount: 0,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU',
        tx_hash: 'UJZVA464VM2SY7AKS426PD3XOOBTRF27DB5OYIT4HCBSKZPFWOZA'
      )
    )
  end

  def algorand_app_mint_tx
    tr = algo_sec_dummy_transfer(type: 'mint', amount: 50)

    Comakery::Algorand::Tx::App::SecurityToken::Mint.new(
      create(
        :blockchain_transaction,
        token: tr.token,
        blockchain_transactables: tr,
        amount: tr.total_amount,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        tx_hash: 'IWT2FUQOQQTGIMOLJAULGAPAU4ZCYE7AZQY7L2U7RFWOHAVXG2EA'
      )
    )
  end

  def algorand_app_pause_tx
    t = create(:algo_sec_token, contract_address: '13997710', token_frozen: false)

    Comakery::Algorand::Tx::App::SecurityToken::Pause.new(
      create(
        :blockchain_transaction_token_freeze,
        token: t,
        blockchain_transactables: t,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        tx_hash: 'EGVNJAAQEUJPOKAPJZIZQBWVOPCIVUTAIDG7X7XCIMOBAY7TCUXQ'
      )
    )
  end

  def algorand_app_set_transfer_rule_tx
    r = algo_sec_dummy_transfer_rule(from: 1, to: 1, lockup_until: 1)

    Comakery::Algorand::Tx::App::SecurityToken::SetTransferRule.new(
      create(
        :blockchain_transaction_transfer_rule,
        token: r.token,
        blockchain_transactables: r,
        amount: 0,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        tx_hash: 'HQU2F6OX2GONFDQRTKTOUG4XYXMGOXVQSTIGKA6R6PNJJPIQWQQQ'
      )
    )
  end

  def algorand_app_transfer_tx
    tr = algo_sec_dummy_transfer(amount: 15)

    Comakery::Algorand::Tx::App::SecurityToken::Transfer.new(
      create(
        :blockchain_transaction,
        token: tr.token,
        blockchain_transactables: tr,
        amount: tr.total_amount,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: '6447K33DMECECFTWCWQ6SDJLY7EYM47G4RC5RCOKPTX5KA5RCJOTLAK7LU',
        tx_hash: 'UV7YMGF6ZQHHLGO63BSPLR5TFV4PYYMHPJDEUIDXMZNVVUCNLIRQ'
      )
    )
  end

  def algorand_app_unpause_tx
    t = create(:algo_sec_token, contract_address: '13997710', token_frozen: true)

    Comakery::Algorand::Tx::App::SecurityToken::Unpause.new(
      create(
        :blockchain_transaction_token_unfreeze,
        token: t,
        blockchain_transactables: t,
        source: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        destination: 'IKSNMZFYNMXFBWB2JCPMEC4HT7UECC354UDCKNHQTNKF7WQG3UQW7YZHWA',
        tx_hash: 'DPPKH4IUFEGGV44TVQPVOOMP2BCGHBDELGBBCC7HBSFMWO2HSS6A'
      )
    )
  end

  def bitcoin_address_1
    '3P3QsMVK89JBNqZQv5zMAKG8FK3kJM4rjt'
  end

  def bitcoin_address_2
    '3FZbgi29cpjq2GjdwV8eyHuJJnkLtktZc5'
  end

  def constellation_address_1
    'DAG8LvRqfJchUjkw5Fpm3DohFqgXhqeqRAVUWKKY'
  end

  def constellation_address_2
    'DAG8PU6Np9zrCfNEcq5bnEco6NdYKtcKgTDnZYwp'
  end

  def dag_tx(**attrs)
    host = attrs[:host] || :constellation_test
    hash = attrs[:hash] || '2dd4f39300c5536005170acbb2eb8bfacf15c0b1d78541c7922813319cfc786d'

    stub_constellation_request(
      host,
      hash,
      'hash' => '2dd4f39300c5536005170acbb2eb8bfacf15c0b1d78541c7922813319cfc786d',
      'amount' => 0,
      'receiver' => 'DAG8LvRqfJchUjkw5Fpm3DohFqgXhqeqRAVUWKKY',
      'sender' => 'DAG8PU6Np9zrCfNEcq5bnEco6NdYKtcKgTDnZYwp'
    )

    Comakery::Dag::Tx.new(
      host,
      hash
    )
  end
end

def token_opt_in(**attrs)
  default_params = {
    wallet: create(:wallet, _blockchain: :algorand_test, address: algorand_address_1),
    token: create(:asa_token)
  }

  TokenOptIn.create!(default_params.merge(attrs))
end

def wallet_provision(**attrs) # rubocop:todo Metrics/CyclomaticComplexity
  wallet = attrs[:wallet] || build(:wallet, _blockchain: :algorand_test, source: :ore_id, address: attrs[:wallet_address] || nil)

  unless wallet.ore_id_account
    wallet.create_ore_id_account(
      account_name: attrs[:ore_id_account_name] || 'ore1raevigpd',
      account_id: wallet.account_id,
      state: attrs[:ore_id_account_state] || :pending
    )
  end
  wallet.save!

  params = {
    wallet: wallet,
    token: attrs[:token] || create(:asa_token)
  }

  attrs.delete(:wallet)
  attrs.delete(:wallet_address)
  attrs.delete(:token)
  attrs.delete(:ore_id_account_name)
  attrs.delete(:ore_id_account_state)

  WalletProvision.new(params.merge(attrs))
end

def api_request_log(**attrs)
  params = {
    signature: 'test_signature',
    ip: IPAddr.new('0.0.0.0'),
    body: {
      test: :test
    }
  }

  ApiRequestLog.new(params.merge(attrs))
end

def ore_id_hmac(url, url_encode: true)
  url_wo_hmac = /^(.+?)(&hmac=\S+|)$/.match(url)[1]
  hmac = OpenSSL::HMAC.digest('SHA256', ENV['ORE_ID_API_KEY'], url_wo_hmac)
  hmac = Base64.strict_encode64(hmac)
  hmac = ERB::Util.url_encode(hmac) if url_encode
  hmac
end

def mom
  @mom ||= Mom.new
end

def build(thing, *args)
  mom.send(thing, *args)
end

def create(thing, *args)
  mom.send(thing, *args).tap(&:save!)
end

def dummy_image
  Rack::Test::UploadedFile.new(
    Rails.root.join('spec/fixtures/dummy_image.png').to_s,
    'image/png'
  )
end
