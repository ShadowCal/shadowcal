require 'test_helper'

class CalendarAccountHelperTest < ActiveSupport::TestCase
  test "account's calendars to select options" do
    calendars = [
      StubCalendar.new('Cal_1', 'First Calendar'),
      StubCalendar.new('Cal_2', 'Second Calendar')
    ]

    account = StubAccount.new('Acc_1', calendars)

    options = CalendarAccountHelper.from_accounts_by_key([account])
    first_group = options[0]

    assert first_group.is_a? Array
    assert first_group[0] == account.email
    assert first_group[1].length == calendars.length

    first_group[1].each_with_index do |opt, i|
      assert opt[0] == calendars[i].summary
      assert opt[1] == [account.email, calendars[i].id].join(':')
    end
  end
end
