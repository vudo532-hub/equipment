FactoryBot.define do
  factory :cute_installation do
    association :user
    sequence(:name) { |n| "CUTE Installation #{n}" }
    sequence(:installation_type) { |n| "Terminal #{n}" }
    sequence(:identifier) { |n| "CUTE-#{n.to_s.rjust(3, '0')}" }
  end
end
