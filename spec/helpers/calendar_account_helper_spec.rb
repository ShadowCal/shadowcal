require "rails_helper"

#require Rails.root.join('app', 'helpers', 'calendar_account_helper.rb')

describe CalendarAccountHelper do
  describe "#from_accounts_by_key" do
    it "groups multiple accounts' calendars as select options" do
      accounts = FactoryGirl.create_list :google_account, 2

      options = CalendarAccountHelper.from_accounts_by_key accounts

      expect(options[0][0]).to eq accounts[0].email
      expect(options[1][0]).to eq accounts[1].email

      expect(options[0][2]).to match_array accounts[0].calendars.map(&:name)
      expect(options[1][2]).to match_array accounts[1].calendars.map(&:name)
    end
  end
end
