FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'Secure1Pass' }
    password_confirmation { 'Secure1Pass' }
    first_name { 'Тест' }
    last_name { 'Пользователь' }
    role { :viewer }

    trait :admin do
      role { :admin }
    end

    trait :editor do
      role { :editor }
    end

    trait :manager do
      role { :manager }
    end

    trait :with_weak_password do
      password { 'weak' }
      password_confirmation { 'weak' }
    end
  end
end
