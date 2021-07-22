FactoryBot.define do
  factory :verification do
    account
    passed { true }
    max_investment_usd { 1_000_000 }
  end
end
