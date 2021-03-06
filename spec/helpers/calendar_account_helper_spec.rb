# frozen_string_literal: true

require "rails_helper"

describe CalendarAccountHelper do
  describe "#from_accounts_by_key" do
    it "groups multiple accounts' calendars as select options" do
      accounts = FactoryBot.create_list :google_account, 2

      options = CalendarAccountHelper.from_accounts_by_key accounts

      expect(options[0][0]).to eq accounts[0].email
      expect(options[1][0]).to eq accounts[1].email

      expect(options[0][1]).to match_array accounts[0].calendars.map(&:name)
      expect(options[1][1]).to match_array accounts[1].calendars.map(&:name)
    end
  end
end
