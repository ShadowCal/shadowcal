# frozen_string_literal: true

require "rails_helper"

describe "GoogleAccount", type: :model do
  let!(:expired_instance) { FactoryBot.create :google_account, :expired }
  let!(:valid_instance) { FactoryBot.create :google_account }

  describe "scope(:to_be_refreshed)" do
    let!(:no_expiry_instance) { FactoryBot.create :google_account, token_expires_at: nil }

    before :each do
      allow_any_instance_of(GoogleAccount).to receive(:refresh_token!)
    end

    it "includes only expired" do
      expect(GoogleAccount.to_be_refreshed.all).to contain_exactly(expired_instance)
    end
  end

  describe "after_initialize" do
    it "refreshes automatically if stale" do
      expired_instance # Create so we can find it, later

      expect_any_instance_of(GoogleAccount).to receive(:refresh_token!)

      GoogleAccount.find(expired_instance.id)
    end

    it "skips refreshing if valid" do
      valid_instance # Create so we can find it, later

      expect_any_instance_of(GoogleAccount).to_not receive(:refresh_token!)

      GoogleAccount.find(valid_instance.id)
    end
  end

  describe "#refresh_token!" do
    let(:new_token) { "asdf" }
    let(:new_expires_at) { 3600 }
    let(:account) { FactoryBot.create :google_account, :expired }

    before :each do
      allow(GoogleCalendarApiHelper).to receive(:refresh_access_token)
        .and_return("access_token" => new_token,
                    "expires_in"   => new_expires_at)
    end

    it "exchanges refresh token for access token" do
      account.send(:refresh_token!)
      expect(account.changed?).to eq false
      expect(account.token_expires_at).to be_within(1.second).of(new_expires_at.seconds.from_now)
      expect(account.access_token).to eq new_token
    end
  end
end
