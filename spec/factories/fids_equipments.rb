FactoryBot.define do
  factory :fids_equipment do
    association :user
    association :fids_installation
    sequence(:equipment_type) { |n| "Display Type #{n}" }
    sequence(:equipment_model) { |n| "Display Model #{n}" }
    sequence(:inventory_number) { |n| "INV-FIDS-#{n.to_s.rjust(5, '0')}" }
    sequence(:serial_number) { |n| "SN-FIDS-#{n.to_s.rjust(8, '0')}" }
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
      fids_installation { nil }
    end
  end
end
