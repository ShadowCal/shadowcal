# frozen_string_literal: true

require "rails_helper"

describe ZoneHelper do
  let(:date_str) { '2017-01-04' }
  let(:zone_str) { 'America/Los_Angeles' }
  let(:datetime_str) { "#{date_str}T09:00:00"}

  describe "#from_date_str_and_zone_to_utc" do
    it "returns that date at 00:00, local time" do
      expect(
        subject
          .from_date_str_and_zone_to_utc(date_str, zone_str)
          .to_s
      ).to eq '2017-01-04T08:00:00+00:00'
    end
  end

  describe "#from_zoneless_timestamp_and_zone_to_utc" do
    it "tells you what utc would be, when the given zone is the given time" do
      expect(
        subject
          .from_zoneless_timestamp_and_zone_to_utc(datetime_str, zone_str)
          .to_s
      ).to eq '2017-01-04T17:00:00+00:00'
    end
  end
end
