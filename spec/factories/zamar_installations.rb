FactoryBot.define do
  factory :zamar_installation do
    association :user
    sequence(:name) { |n| "Место ZAMAR #{n}" }
    installation_type { %w[baggage_hall gate check_in_area].sample }
    terminal { ZamarInstallation.terminals.keys.sample }
    sequence(:identifier) { |n| "ZAMAR-#{n.to_s.rjust(4, '0')}" }

    trait :terminal_a do
      terminal { :terminal_a }
    end

    trait :terminal_b do
      terminal { :terminal_b }
    end

    trait :without_terminal do
      terminal { nil }
    end
  end
end
