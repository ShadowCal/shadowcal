# frozen_string_literal: true

require "rails_helper"

describe "User", type: :model do
  let(:user) { create :user }

  describe "#default_sync_pair" do
    subject { user.default_sync_pair }

    it { is_expected.to be_an_instance_of(SyncPair) }

    context "when user has no accounts" do
      it { is_expected.to have_attributes(from_calendar_id: nil, to_calendar_id: nil) }
    end

    context "when user has an account" do
      let!(:remote_account) { create :remote_account, user: user }
      let!(:first_random_calendar) { create :calendar, remote_account: remote_account }
      let!(:second_random_calendar) { create :calendar, remote_account: remote_account }

      context "with a calendar named Personal" do
        let!(:default_calendar) { create :calendar, name: 'Personal', remote_account: remote_account }

        it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
      end

      context "with a calendar named [email]" do
        let!(:default_calendar) { create :calendar, name: remote_account.email, remote_account: remote_account }

        it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
      end

      it { is_expected.to have_attributes(from_calendar_id: nil, to_calendar_id: nil) }
    end

    context "when user has more than one account" do
      let!(:first_remote_account) { create :remote_account, user: user }
      let!(:first_random_calendar) { create :calendar, remote_account: first_remote_account }
      let!(:second_random_calendar) { create :calendar, remote_account: first_remote_account }

      let!(:second_remote_account) { create :remote_account, user: user }
      let!(:third_random_calendar) { create :calendar, remote_account: second_remote_account }
      let!(:fourth_random_calendar) { create :calendar, remote_account: second_remote_account }

      context "and the first account" do
        let(:remote_account) { first_remote_account }

        context "has a calendar named Personal" do
          let!(:default_calendar) { create :calendar, name: 'Personal', remote_account: remote_account }

          it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
        end

        context "has a calendar named [email]" do
          let!(:default_calendar) { create :calendar, name: first_remote_account.email, remote_account: remote_account }

          it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
        end
      end

      context "and the second account" do
        let(:remote_account) { second_remote_account }

        context "has a calendar named Personal" do
          let!(:default_calendar) { create :calendar, name: 'Personal', remote_account: remote_account }

          it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
        end

        context "has a calendar named [email]" do
          let!(:default_calendar) { create :calendar, name: remote_account.email, remote_account: remote_account }

          it { is_expected.to have_attributes(from_calendar_id: default_calendar.id, to_calendar_id: nil) }
        end
      end

      context "and both accounts" do
        context "have a calendar named Personal" do
          let!(:first_default_calendar) { create :calendar, name: 'Personal', remote_account: first_remote_account }
          let!(:second_default_calendar) { create :calendar, name: 'Personal', remote_account: second_remote_account }

          it { is_expected.to have_attributes(from_calendar_id: first_default_calendar.id, to_calendar_id: second_default_calendar.id) }
        end

        context "have a calendar named [email]" do
          let!(:first_default_calendar) { create :calendar, name: first_remote_account.email, remote_account: first_remote_account }
          let!(:second_default_calendar) { create :calendar, name: second_remote_account.email, remote_account: second_remote_account }

          it { is_expected.to have_attributes(from_calendar_id: first_default_calendar.id, to_calendar_id: second_default_calendar.id) }
        end
      end

      it { is_expected.to have_attributes(from_calendar_id: nil, to_calendar_id: nil) }
    end
  end

  describe "#add_or_update_remote_account" do
    let(:access_token) { Faker::Omniauth.unique.google.to_ostruct }

    before :each do
      expect(user.remote_accounts.count).to eq 0 # sanity

      # Don't actually refresh the token
      allow_any_instance_of(RemoteAccount)
        .to receive(:refresh_token!)

      # Don't actually fetch calendars
      allow_any_instance_of(RequestCalendarsJob)
        .to receive(:perform)

      user.add_or_update_remote_account(access_token, nil)
    end

    context "with a basic acccount" do
      it "adds a new RemoteAccount" do
        expect(user.remote_accounts.count).to eq 1
      end

      it "adds a second RemoteAccount" do
        new_access_token = Faker::Omniauth.unique.google.to_ostruct

        expect(user.remote_accounts.count).to eq 1 # sanity

        user.add_or_update_remote_account(new_access_token, nil)

        expect(user.remote_accounts.count).to eq 2
      end
    end

    context "without expires_at" do
      after(:each) do
        expect(user.remote_accounts.count).to eq 1 # sanity
      end

      context "with refresh_token" do
        it "defaults expiry to 40 minutes" do
          access_token.credentials.refresh_token = 'abc123'
          access_token.credentials.expires_at = nil
          user.add_or_update_remote_account(access_token, nil)
          user.remote_accounts.reload
          expect(user.remote_accounts.last.token_expires_at).to be_within(1.second).of(40.minutes.from_now)
        end
      end

      context "without refresh_token" do
        it "leaves expires_at nil" do
          access_token.credentials.expires_at = nil
          access_token.credentials.refresh_token = nil

          allow(Rollbar)
            .to receive(:error)
            .with RemoteAccount::SavedWithoutRefreshToken

          user.add_or_update_remote_account(access_token, nil)
          user.remote_accounts.reload
          expect(user.remote_accounts.last.token_expires_at).to be_nil
        end
      end
    end

    it "records refresh_token" do
      expect(user.remote_accounts.first.refresh_token).to_not be_nil
    end
  end
end
