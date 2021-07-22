FactoryBot.define do
  factory :account do
    email { Faker::Internet.email }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    date_of_birth { '1990/01/01' }
    country { 'United States of America' }

    trait :unconfirmed do
      email_confirm_token { SecureRandom.hex(6) }
    end

    trait :verified do
      verifications { [association(:verification)] }
    end

    trait :verification_failed do
      verifications { [association(:verification, passed: false)] }
    end
  end
end
