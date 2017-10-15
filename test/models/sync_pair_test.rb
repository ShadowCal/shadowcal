require 'test_helper'

class SyncPairTest < ActiveSupport::TestCase
  test "setting from_calendar" do
    sp = SyncPair.new

    cal_id = '123'
    google_account_id = 432

    sp.from_calendar_id = "#{google_account_id}:#{cal_id}"

    assert sp.from_cal_id == cal_id
    assert sp.from_google_account_id == google_account_id
  end

  test "setting to_calendar" do
    sp = SyncPair.new

    cal_id = '123'
    google_account_id = 432

    sp.to_calendar_id = "#{google_account_id}:#{cal_id}"

    assert sp.to_cal_id == cal_id
    assert sp.to_google_account_id == google_account_id
  end

  test "getting from_calendar" do
    sp = SyncPair.new

    cal_id = '123'
    google_account_id = 432

    sp.from_cal_id = cal_id
    sp.from_google_account_id = google_account_id

    assert sp.from_calendar_id == "#{google_account_id}:#{cal_id}"
  end

  test "getting to_calendar" do
    sp = SyncPair.new

    cal_id = '123'
    google_account_id = 432

    sp.to_cal_id = cal_id
    sp.to_google_account_id = google_account_id

    assert sp.to_calendar_id == "#{google_account_id}:#{cal_id}"
  end
end
