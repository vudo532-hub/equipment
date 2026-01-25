# frozen_string_literal: true

FactoryBot.define do
  factory :repair_batch_item do
    association :repair_batch
    equipment_type { 'CuteEquipment' }
    sequence(:equipment_id) { |n| n }
    system { 'cute' }
    sequence(:serial_number) { |n| "SN-REPAIR-#{n.to_s.rjust(5, '0')}" }
    model { "Test Model" }
    terminal { 'T1' }
    installation_name { 'Test Installation' }

    trait :fids do
      equipment_type { 'FidsEquipment' }
      system { 'fids' }
    end

    trait :zamar do
      equipment_type { 'ZamarEquipment' }
      system { 'zamar' }
    end
  end
end
