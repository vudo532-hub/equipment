FactoryBot.define do
  factory :api_token do
    association :user
    sequence(:name) { |n| "API Token #{n}" }
    token { SecureRandom.hex(32) }
    expires_at { 1.year.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :never_expires do
      expires_at { nil }
    end
  end
end
