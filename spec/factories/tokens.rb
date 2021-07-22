FactoryBot.define do
  factory :token do
    sequence(:name) { |n| "Token #{n}" }
    coin_type { :btc }
    denomination { :BTC }
    symbol { :BTC }
    blockchain_network { :bitcoin_mainnet }
    _blockchain { :bitcoin }
    decimal_places { 0 }

    trait :security_token do
      logo_image { Rack::Test::UploadedFile.new('spec/fixtures/dummy_image.png', 'image/png') }
      contract_address { '0x1d1592c28fff3d3e71b1d29e31147846026a0a37' }
      _token_type { :comakery_security_token }
      _blockchain { :ethereum_ropsten }
      symbol { :XYZ2 }
      decimal_places { 0 }
    end

    trait :eth do
      symbol { nil }
      _token_type { :eth }
    end

    trait :ropsten do
      _blockchain { :ethereum_ropsten }
    end

    trait :erc20_with_batch do
      contract_address { '0x9608848FA0063063d2Bb401e8B5efFcb8152Ec65' }
      _blockchain { :ethereum_ropsten }
      _token_type { :erc20 }
      batch_contract_address { '0x68ac9a329c688afbf1fc2e5d3e8cb6e88989e2cc' }
    end

    trait :lockup do
      contract_address { '0x9608848FA0063063d2Bb401e8B5efFcb8152Ec65' }
      batch_contract_address { nil }
      _token_type { :token_release_schedule }
      _blockchain { :ethereum_rinkeby }
      decimal_places { 10 }
    end
  end
end
