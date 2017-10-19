FactoryGirl.define do
  factory :event do
    calendar nil
    name "MyString"
    start_at "2017-10-18 18:13:03"
    end_at "2017-10-18 18:13:03"
    shadow_of_event nil
  end
  factory :sync_pair do
    from_cal_id "MyString"
    from_google_account 1
    to_cal_id "MyString"
    to_google_account 1
  end
  factory :google_account do
    user ""
    access_token "MyString"
    token_secret "MyString"
    token_expires ""
  end
  factory :calendar do
    user ""
    access_token "MyString"
    token_secret "MyString"
    token_expires ""
  end
  sequence :email do |n|
    "test#{n}@example.com"
  end

  to_create do |i|
    without_callbacks do
      i.save!
    end
    i
  end
end