# frozen_string_literal: true

require "rails_helper"

describe "Calendar", type: :model do
  let(:calendar) { build :calendar }
  let(:events) { double('events') }
  let(:event) { double('event') }

  describe "#push_events" do
    it "delegates to remote_account" do
      expect(calendar.remote_account)
        .to receive(:push_events)
        .with(calendar.external_id, events)

      calendar.push_events(events)
    end
  end

  describe "#move_event" do
    it "delegates to remote_account" do
      start_at = double('start_at')
      end_at = double('end_at')

      expect(calendar.remote_account)
        .to receive(:move_event)
        .with(calendar.external_id, event, start_at, end_at)

      calendar.move_event(event, start_at, end_at)
    end
  end
end
