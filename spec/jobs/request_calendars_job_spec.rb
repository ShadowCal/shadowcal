# frozen_string_literal: true

require "rails_helper"

describe SyncPairPerformSyncJob do
  let(:account) { create :remote_account }
  let(:remote_account_id) { account.id }
  let(:job) { RequestCalendarsJob.new(remote_account_id) }

  describe "#perform" do
    subject { job.perform }

    let(:instance) { double("remote_account") }
    let(:calendar) { create :calendar, remote_account: account }

    before(:each) {
      expect(RemoteAccount)
        .to receive(:find)
        .with(remote_account_id)
        .and_return(account)

      expect(account)
        .to receive(:request_calendars)
        .and_return([calendar])
    }

    after(:each) {
      expect(account.calendars)
        .to include(calendar)
    }

    it { is_expected.to be true }
  end

  describe "#error" do
    let(:error) { double("the error") }
    let(:delayed_job_instance) { double("job instance") }

    subject { job.error(delayed_job_instance, error) }

    before(:each) {
      expect(Rollbar)
        .to receive(:error)
        .with(error, anything)
    }

    it { is_expected.to be_nil }
  end

  describe "#error_details" do
    subject { job.error_details }

    context "with missing remote_account_id" do
      let(:remote_account_id) { '123' }

      it {
        is_expected.to include(
          remote_account_id: remote_account_id,
          remote_account:    nil,
        )
      }
    end

    context "with valid remote_account_id" do
      it {
        is_expected.to include(
          remote_account_id: remote_account_id,
          remote_account:    include(
            'id' => remote_account_id,
          ),
          user:              include(
            'id' => account.user.id,
          ),
        )
      }
    end
  end
end
