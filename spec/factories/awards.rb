FactoryBot.define do
  factory :award do
    account
    award_type
    issuer { account }
    sequence(:name) { |n| "Award #{n}" }
    amount { 10 }
    image { dummy_image }

    trait :paid do
      status { :paid }
    end

    trait :ropsten do
      association :award_type, factory: %i[award_type ropsten]
    end

    trait :with_recipient_wallet do
      ropsten
      recipient_wallet { association :wallet, _blockchain: :ethereum_ropsten, address: '0x42D00fC2Efdace4859187DE4865Df9BaA320D5dB', account: account }
    end

    trait :with_verified_account do
      association :account, :verified
    end

    trait :with_verification_failed_account do
      association :account, :verification_failed
    end
  end
end
