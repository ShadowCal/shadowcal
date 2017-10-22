FactoryGirl.define do
  factory :event do
    calendar
    name { Faker::Company.bs }
    start_at { Faker::Time.forward(1, :afternoon) }
    end_at { start_at + 30.minutes }
  end

  factory :sync_pair do
    user
    from_calendar { build(:calendar, user: user) }
    to_calendar { build(:calendar, user: user)}

    after :build do |pair|
      pair.stub(:perform_sync).and_return(true)
    end
  end

  factory :google_account do
    user
    email
    access_token { Faker::Internet.password(10, 20) }
    token_secret { Faker::Internet.password(10, 20) }
    token_expires { 1.month.from_now }

    after :build do |acc|
      acc.stub(:fetch_calendars).and_return(true)
    end
  end

  factory :calendar do
    transient do
      user build(:user)
    end

    external_id { generate(:calendar_id) }

    after :create do |calendar, evaluator|
      create :google_account, user: evaluator.user, calendars: [calendar] if calendar.google_account.nil?
    end
  end

  factory :user do
    email
    password 'password'

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
