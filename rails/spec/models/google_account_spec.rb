# frozen_string_literal: true

require "rails_helper"

describe "GoogleAccount", type: :model do
  describe "#calendar_helper" do
    subject { GoogleAccount.calendar_helper }

    it { is_expected.to eq CalendarApiHelper::Google }
  end

  describe "#request_calendars" do
    let(:account) { create :google_account }
    let(:calendar) { build :calendar }

    subject { account.request_calendars }

    before(:each) {
      expect(CalendarApiHelper::Google)
        .to receive(:request_calendars)
        .with(account.access_token)
        .and_return([calendar])
    }

    it { is_expected.to include(calendar) }
  end
end
