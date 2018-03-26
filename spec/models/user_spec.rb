# frozen_string_literal: true

require "rails_helper"

describe "User", type: :model do
  let(:user) { FactoryBot.create :user }

  describe "#add_or_update_google_account" do
    let(:access_token) { Faker::Omniauth.unique.google.to_ostruct }

    before :each do
      allow(GoogleCalendarApiHelper)
        .to receive(:request_calendars)
        .with(access_token.credentials.token)
        .and_return([])

      expect(user.google_accounts.count).to eq 0 # sanity

      user.add_or_update_google_account(access_token)
    end

    context "with a basic acccount" do
      it "adds a new google account" do
        expect(user.google_accounts.count).to eq 1
      end

      it "adds a second google account" do
        new_access_token = Faker::Omniauth.unique.google.to_ostruct

        allow(GoogleCalendarApiHelper)
          .to receive(:request_calendars)
          .with(new_access_token.credentials.token)
          .and_return([])

        expect(user.google_accounts.count).to eq 1 # sanity

        user.add_or_update_google_account(new_access_token)
        expect(user.google_accounts.count).to eq 2
      end
    end

    context "without expires_at" do
      after(:each) do
        expect(user.google_accounts.count).to eq 1 # sanity
      end

      context "with refresh_token" do
        it "defaults expiry to 40 minutes" do
          access_token.credentials.refresh_token = 'abc123'
          access_token.credentials.expires_at = nil
          user.add_or_update_google_account(access_token)
          user.google_accounts.reload
          expect(user.google_accounts.last.token_expires_at).to be_within(1.second).of(40.minutes.from_now)
        end
      end

      context "without refresh_token" do
        it "leaves expires_at nil" do
          access_token.credentials.expires_at = nil
          access_token.credentials.refresh_token = nil
          user.add_or_update_google_account(access_token)
          user.google_accounts.reload
          expect(user.google_accounts.last.token_expires_at).to be_nil
        end
      end
    end

    it "records refresh_token" do
      expect(user.google_accounts.first.refresh_token).to_not be_nil
    end
  end
end
