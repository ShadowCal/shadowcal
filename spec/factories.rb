# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    calendar
    name { Faker::Company.bs }
    start_at { Faker::Time.forward(1, :afternoon) }
    end_at { start_at + 30.minutes }

    trait :is_shadow do
      after :create do |event|
        event.source_event = create :event
        event.save!
      end
    end

    trait :has_shadow do
      association :shadow_event, factory: :event
    end
  end

  factory :sync_pair do
    user
    from_calendar { build(:calendar, user: user) }
    to_calendar { build(:calendar, user: user) }
    last_synced_at nil
  end

  factory :google_account do
    user
    email
    access_token { Faker::Internet.password(10, 20) }
    refresh_token { Faker::Internet.password(10, 20) }
    token_secret { Faker::Internet.password(10, 20) }
    token_expires_at { 1.month.from_now }

    trait :expired do
      token_expires_at 1.minute.ago
    end
  end

  factory :calendar do
    transient do
      user { build(:user) }
    end

    external_id { generate(:calendar_id) }

    after :create do |calendar, evaluator|
      create :google_account, user: evaluator.user, calendars: [calendar] if calendar.google_account.nil?
    end
  end

  factory :user do
    email
    password "password"

    factory :user_with_google_account do
      transient do
        num_google_accounts 1
      end

      after(:create) do |user, evaluator|
        create_list(:google_account, evaluator.num_google_accounts, user: user)
      end
    end
  end

  sequence :calendar_id do |n|
    "Calendar_#{n}"
  end

  sequence :email do |n|
    "test#{n}@example.com"
  end
end
