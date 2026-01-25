# frozen_string_literal: true

FactoryBot.define do
  factory :repair_batch do
    association :user
    status { 'sent' }

    trait :in_progress do
      status { 'in_progress' }
    end

    trait :received do
      status { 'received' }
    end

    trait :closed do
      status { 'closed' }
    end
  end
end
