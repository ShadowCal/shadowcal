FactoryGirl.define do
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