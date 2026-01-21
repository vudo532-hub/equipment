FactoryBot.define do
  factory :cute_equipment do
    association :user
    association :cute_installation
    sequence(:equipment_type) { |n| "Type #{n}" }
    sequence(:equipment_model) { |n| "Model #{n}" }
    sequence(:inventory_number) { |n| "INV-CUTE-#{n.to_s.rjust(5, '0')}" }
    sequence(:serial_number) { |n| "SN-#{n.to_s.rjust(8, '0')}" }
    status { :active }
    note { Faker::Lorem.sentence }
    last_action_date { Time.current }

    trait :inactive do
      status { :inactive }
    end

    trait :maintenance do
      status { :maintenance }
    end

    trait :archived do
      status { :archived }
    end

    trait :without_installation do
      cute_installation { nil }
    end
  end
end
