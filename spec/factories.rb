# frozen_string_literal: true

require Rails.root.join("spec", "support", 'test_remote_account.rb')

FactoryBot.define do
  factory :event do
    calendar
    name { Faker::Company.bs }
    start_at { ActiveSupport::TimeZone.new(calendar.time_zone).parse('03:00:00').utc }
    end_at { start_at + 30.minutes }
    is_attending false

    factory :syncable_event, traits: %i{work_hours weekday is_attending is_busy}

    trait :is_attending do
      is_attending true
    end

    trait :is_busy do
      is_busy true
    end

    trait :is_shadow do
      name "(Busy)"
      external_id { Faker::Internet.password(10, 20) }

      after :create do |event|
        user = event.calendar.remote_account.user
        pair = user.sync_pairs.find do |sp|
          sp.to_calendar == event.calendar
        end
        pair ||= create :sync_pair, user: user, to_calendar: event.calendar

        if event.source_event.nil?
          event.source_event = create :event, calendar: pair.from_calendar
          event.save!
        end

        user.reload
      end
    end

    trait :work_hours do
      start_at { ActiveSupport::TimeZone.new(calendar.time_zone).parse('09:30:00').utc }
      end_at { start_at + 30.minutes }
    end

    trait :after_work_hours do
      start_at { ActiveSupport::TimeZone.new(calendar.time_zone).parse('20:30:00').utc }
      end_at { start_at + 30.minutes }
    end

    trait :all_day do
      start_at { ActiveSupport::TimeZone.new(calendar.time_zone).parse('00:00:00').utc + 3.days }
      end_at { ActiveSupport::TimeZone.new(calendar.time_zone).parse('23:59:59').utc + 3.days }
    end

    trait :has_shadow do
      after(:create) do |event|
        user = event.calendar.remote_account.user
        pair = user.sync_pairs.find do |sp|
          sp.from_calendar == event.calendar
        end
        pair ||= create :sync_pair, user: user, from_calendar: event.calendar

        if event.shadow_event.nil?
          event.shadow_event = create :event, calendar: pair.to_calendar, source_event: event
          event.save!
        end

        user.reload
      end
    end

    trait :weekday do
      before(:create) do |event|
        duration = event.end_at - event.start_at
        event.start_at += (1 + ((3 - event.start_at.wday) % 7)).days
        event.end_at = event.start_at + duration
      end
    end

    trait :weekend do
      before(:create) do |event|
        duration = event.end_at - event.start_at
        event.start_at += (1 + (6 - event.start_at.wday % 7)).days
        event.end_at = event.start_at + duration
      end
    end
  end

  factory :sync_pair do
    user
    from_calendar { build(:calendar, user: user) }
    to_calendar { build(:calendar, user: user) }
    last_synced_at nil
  end

  factory :remote_account, class: TestRemoteAccount do
    user
    email
    access_token { Faker::Internet.password(10, 20) }
    refresh_token { Faker::Internet.password(10, 20) }
    token_secret { Faker::Internet.password(10, 20) }
    token_expires_at { 1.month.from_now }
    type 'TestRemoteAccount'

    trait :expired do
      token_expires_at 1.minute.ago
    end

    factory :google_account, class: GoogleAccount do
    end

    factory :outlook_account, class: OutlookAccount do
    end
  end

  factory :calendar do
    transient do
      user { build(:user) }
    end

    name { generate(:calendar_id) }
    external_id { Faker::Internet.password(10, 20) }
    remote_account { build :remote_account, user: user }
    time_zone 'America/Los_Angeles'
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

  to_create do |model|
    ActiveRecord::Base.skip_callbacks = true
    model.save!
    ActiveRecord::Base.skip_callbacks = false
  end
end
