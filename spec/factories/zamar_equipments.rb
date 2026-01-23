FactoryBot.define do
  factory :zamar_equipment do
    equipment_type { ZamarEquipment.equipment_types.keys.sample }
    sequence(:inventory_number) { |n| "ZAMAR-INV-#{n.to_s.rjust(6, '0')}" }
    sequence(:serial_number) { |n| "SN-ZAMAR-#{n}" }
    equipment_model { "Model #{Faker::Alphanumeric.alphanumeric(number: 8).upcase}" }
    status { :active }
    association :zamar_installation
    association :user
    association :last_changed_by, factory: :user

    trait :without_installation do
      zamar_installation { nil }
    end

    trait :active do
      status { :active }
    end

    trait :maintenance do
      status { :maintenance }
    end

    trait :decommissioned do
      status { :decommissioned }
    end

    trait :with_note do
      note { Faker::Lorem.paragraph }
    end
  end
end
