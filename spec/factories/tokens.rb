FactoryBot.define do
  factory :token do
    name { 'Bitcoin' }
    denomination { :BTC }
    coin_type { :btc }
    blockchain_network { :bitcoin_mainnet }
    symbol { :BTC }
  end
end
