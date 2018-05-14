# frozen_string_literal: true

require "rails_helper"

describe "GoogleAccount", type: :model do
  describe "#request_calendars" do
    let(:account) { create :google_account }
    let(:calendar) { build :calendar }

    subject { account.request_calendars }

    before(:each) {
      expect(GoogleCalendarApiHelper)
        .to receive(:request_calendars)
        .with(account.access_token)
        .and_return([calendar])
    }

    it { is_expected.to include(calendar) }
  end

  describe "#refresh_token!" do
    let(:new_token) { "asdf" }
    let(:new_expires_at) { 3600 }
    let(:account) { create :google_account, :expired }

    before :each do
      expect(GoogleCalendarApiHelper).to receive(:refresh_access_token)
        .and_return("access_token" => new_token,
                    "expires_in"   => new_expires_at)
    end

    it "exchanges refresh token for access token" do
      account.refresh_token!
      expect(account.changed?).to eq false
      expect(account.token_expires_at).to be_within(1.second).of(new_expires_at.seconds.from_now)
      expect(account.access_token).to eq new_token
    end
  end
end
