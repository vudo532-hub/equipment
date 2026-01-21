FactoryBot.define do
  factory :fids_equipment do
    user { nil }
    fids_installation { nil }
    equipment_type { "MyString" }
    equipment_model { "MyString" }
    inventory_number { "MyString" }
    serial_number { "MyString" }
    status { 1 }
    note { "MyText" }
    last_action_date { "2026-01-21 16:02:45" }
  end
end
