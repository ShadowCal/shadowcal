# frozen_string_literal: true

require "rails_helper"

describe "Event", type: :model do
  let(:event) { FactoryBot.create :event }
  let(:new_event) { FactoryBot.build :event }

  describe "#moved?" do
    it "returns true if start date was changed" do
      event.start_at = event.start_at + 1.minute
      expect(event.moved?).to be_truthy
    end

    it "returns true if end date was changed" do
      event.end_at = event.end_at + 1.minute
      expect(event.moved?).to be_truthy
    end

    it "returns false if neither has changed" do
      event.name = "Not #{event.name}"
      expect(event.moved?).to be_falsy
    end

    it "returns false if the object is new" do
      new_event.start_at = new_event.start_at + 1.minute
      expect(new_event.moved?).to be_falsy
    end
  end
end
