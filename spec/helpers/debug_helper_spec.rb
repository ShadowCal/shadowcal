# frozen_string_literal: true

require "rails_helper"

describe DebugHelper do
  describe "#identify_event" do
    subject { DebugHelper.identify_event(event) }
    context "with new event" do
      let(:event) { build :event, name: "event.name" }

      it "says the name of the event" do
        expect(subject).to include("event.name")
      end

      it "says 'new'" do
        expect(subject).to include("new")
      end
    end
    context "with saved event" do
      let(:event) { create :event, name: "event.name" }

      it "says the name of the event" do
        expect(subject).to include("event.name")
      end

      it "says the id" do
        expect(event.id).not_to be_nil # sanity
        expect(subject).to include("##{event.id}")
      end
    end

    context "with event with no start_at" do
      let(:event) { build :event, start_at: nil, end_at: nil }

      it "doesn't crash" do
        expect(subject).to include("Bad start_at")
      end
    end

    context "with source event" do
      let(:event) { create :event, :has_shadow, name: "event.name" }

      it "says name of event" do
        expect(subject).to start_with('"event.name"')
      end
    end

    context "with shadow event" do
      let(:source_event) { create :event, :has_shadow, name: 'SourceEvent' }
      let(:event) { source_event.shadow_event }

      it "says name of source event" do
        expect(subject).to start_with('(Shadow of "SourceEvent"')
      end
    end
  end
end
