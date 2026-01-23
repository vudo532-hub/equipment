FactoryBot.define do
  factory :cute_equipment do
    association :user
    association :cute_installation
    equipment_type { CuteEquipment.equipment_types.keys.sample }
    sequence(:equipment_model) { |n| "Model #{n}" }
    sequence(:inventory_number) { |n| "INV-CUTE-#{n.to_s.rjust(5, '0')}" }
    sequence(:serial_number) { |n| "SN-#{n.to_s.rjust(8, '0')}" }
    status { :active }
    note { Faker::Lorem.sentence }
    last_action_date { Time.current }

    trait :maintenance do
      status { :maintenance }
    end

    trait :decommissioned do
      status { :decommissioned }
    end

    trait :waiting_repair do
      status { :waiting_repair }
    end

    trait :without_installation do
      cute_installation { nil }
    end
  end
end
