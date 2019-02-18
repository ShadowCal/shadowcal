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

  describe "#default_calendar" do
    subject { account.default_calendar }

    context "without any calendars" do
      it { is_expected.to be_nil }
    end

    context "with a calendar" do
      let!(:random_calendar) { create :calendar, remote_account: account }

      it { is_expected.to be_nil }

      context "that should be default" do
        let!(:default_calendar) { create :calendar, remote_account: account, name: calendar_name }

        context "named Personal" do
          let(:calendar_name) { 'Personal' }
          it { is_expected.to eq(default_calendar) }
        end

        context "with a calendar named [email]" do
          let(:calendar_name) { account.email }
          it { is_expected.to eq(default_calendar) }
        end

        context "with a calendar named Personal and named [email]" do
          let(:calendar_name) { account.email }
          let!(:personal_calendar) { create :calendar, remote_account: account, name: "Personal" }
          it { is_expected.to eq(personal_calendar) }
        end
      end
    end
  end

  describe "SyncingError" do
    it "saves attributes to instance variables" do
      e = RemoteAccount::SyncingError.new("test message", valid_instance)
      expect(e.instance_variable_get('@remote_account_data'))
        .to include(
          id: valid_instance.id,
          type: valid_instance.type,
        )

      expect(e.instance_variable_get('@remote_account_data'))
        .not_to include(:email, :access_token, :token_secret, :refresh_token)

      expect(e.message)
        .to eq("test message")
    end
  end

  describe "ensure_refresh_token!" do
    let(:account) { create :remote_account }

    context "when saved without refresh token" do
      before(:each) {
        expect(Rollbar)
          .to receive(:error)
          .with RemoteAccount::SavedWithoutRefreshToken.new(account)
      }

      subject { account.update_attributes refresh_token: nil }

      it { is_expected.to be_truthy }
    end

    context "when saved with refresh token" do
      before(:each) {
        expect(Rollbar)
          .not_to receive(:error)
      }

      subject { account.update_attributes refresh_token: 'not nil' }

      it { is_expected.to be_truthy }
    end
  end

  describe "after_initialize" do
    it "refreshes automatically if stale" do
      expired_instance # Create so we can find it, later

      expect_any_instance_of(TestRemoteAccount).to receive(:refresh_token!)

      RemoteAccount.find(expired_instance.id)
    end

    it "skips refreshing if valid" do
      valid_instance # Create so we can find it, later

      expect_any_instance_of(RemoteAccount).to_not receive(:refresh_token!)

      RemoteAccount.find(valid_instance.id)
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

      across_time_zones do
        it { is_expected.to eq true }
      end

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
