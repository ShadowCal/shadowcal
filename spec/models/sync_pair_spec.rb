# frozen_string_literal: true

require "rails_helper"

describe "SyncPair", type: :model do
  let(:sync_pair) { FactoryBot.create :sync_pair }

  describe "#ownership" do
    let(:other_users_calendar) { FactoryBot.create :calendar }

    it "requires user to own from_calendar" do
      expect(sync_pair.update_attributes from_calendar: other_users_calendar)
        .to be_falsy

      expect(sync_pair.errors)
        .to include(:from_calendar_id)
    end

    it "requires user to own to_calendar" do
      expect(sync_pair.update_attributes to_calendar: other_users_calendar)
        .to be_falsy

      expect(sync_pair.errors)
        .to include(:to_calendar_id)
    end
  end
end
