# frozen_string_literal: true

require "rails_helper"

describe "OutlookAccount", type: :model do
  describe "#calendar_helper" do
    subject { OutlookAccount.calendar_helper }

    it { is_expected.to eq CalendarApiHelper::Outlook }
  end

  describe "#request_calendars" do
    let(:account) { create :outlook_account }
    let(:calendar) { build :calendar }

    subject { account.request_calendars }

    before(:each) {
      expect(CalendarApiHelper::Outlook)
        .to receive(:request_calendars)
        .with(account.access_token)
        .and_return([calendar])
    }

    it { is_expected.to include(calendar) }
  end
end
