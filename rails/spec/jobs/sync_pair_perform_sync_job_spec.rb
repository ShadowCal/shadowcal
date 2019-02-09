# frozen_string_literal: true

require "rails_helper"

describe SyncPairPerformSyncJob do
  let(:pair) { create :sync_pair }
  let(:sync_pair_id) { pair.id }
  let(:job) { SyncPairPerformSyncJob.new(sync_pair_id) }

  describe "#perform" do
    subject { job.perform }

    let(:instance) { double("sync pair") }

    before(:each) {
      expect(instance)
        .to receive(:perform_sync)

      expect(SyncPair)
        .to receive(:find)
        .with(sync_pair_id)
        .and_return(instance)
    }

    it { is_expected.to be_nil }
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

    context "with missing sync_pair_id" do
      let(:sync_pair_id) { '123' }

      it {
        is_expected.to include(
          sync_pair_id: sync_pair_id,
          sync_pair: nil,
        )
      }
    end

    context "with valid sync_pair_id" do
      it {
        is_expected.to include(
          sync_pair_id: sync_pair_id,
          sync_pair: include(
            'id' => sync_pair_id,
          ),
          from_calendar: include(
            'id' => pair.from_calendar.id,
          ),
          to_calendar: include(
            'id' => pair.to_calendar.id,
          ),
        )
      }
    end
  end
end
