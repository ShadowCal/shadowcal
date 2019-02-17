# frozen_string_literal: true

require "rails_helper"

describe "SyncPair", type: :model do
  let(:sync_pair) { FactoryBot.create :sync_pair }

  describe "#no_syncing_to_from_same" do
    it "won't allow user to sync to and from same calendar" do
      expect(sync_pair.update_attributes to_calendar_id: sync_pair.from_calendar_id)
        .to be_falsy

      expect(sync_pair.errors)
        .to include(:base)
    end
  end

  describe "#one_way_syncing" do
    let(:other_pair) { FactoryBot.create :sync_pair, user: sync_pair.user }

    it "won't allow a calendar to be synced from if already being synced to" do
      new_calendar = FactoryBot.create :calendar, user: sync_pair.user
      sync_pair.from_calendar = other_pair.to_calendar

      expect(sync_pair.save)
        .to be_falsy

      expect(sync_pair.errors)
        .to include(:from_calendar_id)
    end

    it "won't allow a calendar to be synced to if already being synced from" do
      new_calendar = FactoryBot.create :calendar, user: sync_pair.user
      sync_pair.to_calendar = other_pair.from_calendar

      expect(sync_pair.save)
        .to be_falsy

      expect(sync_pair.errors)
        .to include(:to_calendar_id)
    end

    it "will allow the record to save" do
      expect(sync_pair.update_attributes last_synced_at: Time.zone.now)
        .to be_truthy
    end
  end

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
