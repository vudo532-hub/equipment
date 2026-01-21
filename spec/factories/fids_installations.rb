FactoryBot.define do
  factory :fids_installation do
    association :user
    sequence(:name) { |n| "FIDS Installation #{n}" }
    sequence(:installation_type) { |n| "Display #{n}" }
    sequence(:identifier) { |n| "FIDS-#{n.to_s.rjust(3, '0')}" }
  end
end
