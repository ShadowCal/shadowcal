# frozen_string_literal: true

require "rails_helper"

describe ZoneHelper do
  let(:date_str) { '2017-01-04' }
  let(:zone_str) { 'America/Los_Angeles' }

  describe "#from_date_str_and_zone_to_utc" do
    it "returns that date at 00:00, local time" do
      expect(
        subject
          .from_date_str_and_zone_to_utc(date_str, zone_str)
          .to_s
      ).to eq '2017-01-04T08:00:00+00:00'
    end
  end
end
