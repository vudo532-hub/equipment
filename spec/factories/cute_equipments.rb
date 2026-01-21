FactoryBot.define do
  factory :cute_equipment do
    user { nil }
    cute_installation { nil }
    equipment_type { "MyString" }
    equipment_model { "MyString" }
    inventory_number { "MyString" }
    serial_number { "MyString" }
    status { 1 }
    note { "MyText" }
    last_action_date { "2026-01-21 16:02:30" }
  end
end
