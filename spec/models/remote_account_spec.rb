# frozen_string_literal: true

require "rails_helper"

describe "RemoteAccount", type: :model do
  let!(:expired_instance) { create :remote_account, :expired }
  let!(:valid_instance) { create :remote_account }
  let(:account) { create :remote_account }

  describe "scope(:to_be_refreshed)" do
    let!(:no_expiry_instance) { create :remote_account, token_expires_at: nil }

    before :each do
      allow_any_instance_of(RemoteAccount).to receive(:refresh_token!)
    end

    it "includes only expired" do
      expect(RemoteAccount.to_be_refreshed.all).to contain_exactly(expired_instance)
    end
  end

  describe "after_initialize" do
    it "refreshes automatically if stale" do
      expired_instance # Create so we can find it, later

      expect_any_instance_of(RemoteAccount).to receive(:refresh_token!)

      RemoteAccount.find(expired_instance.id)
    end

    it "skips refreshing if valid" do
      valid_instance # Create so we can find it, later

      expect_any_instance_of(RemoteAccount).to_not receive(:refresh_token!)

      RemoteAccount.find(valid_instance.id)
    end
  end

  describe "#request_calendars" do
    it "throws an error" do
      expect{ account.request_calendars }.to raise_error NotImplementedError
    end
  end

  describe "#refresh_token!" do
    it "throws an error" do
      expect{ account.send(:refresh_token!) }.to raise_error NotImplementedError
    end
  end

  describe "#should_refresh_token?" do
    subject { account.send(:should_refresh_token?) }

    context "when skipping callbacks" do
      before(:each) {
        allow(RemoteAccount)
          .to receive(:skip_callbacks)
          .and_return(true)
      }

      it { is_expected.to be_falsy }
    end

    context "when expired" do
      let(:account) { FactoryBot.create :remote_account, :expired }

      it { is_expected.to eq true }

      context "when refresh token is blank" do
        before(:each) {
          allow(account)
            .to receive(:refresh_token)
            .and_return(nil)
        }

        it { is_expected.to be_falsy }
      end

      context "when expires at is nil" do
        before(:each) {
          allow(account)
            .to receive(:token_expires_at)
            .and_return(nil)
        }

        it { is_expected.to be_falsy }
      end
    end
  end
end
