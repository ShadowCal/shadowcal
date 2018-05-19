# frozen_string_literal: true

module ZoneHelper
  def from_date_str_and_zone_to_utc(date_str, zone_str)
    ActiveSupport::TimeZone.new(zone_str).local_to_utc(date_str.to_date.to_datetime)
  end

  def from_zoneless_timestamp_and_zone_to_utc(timestamp, from_zone)
    ActiveSupport::TimeZone.new(from_zone).local_to_utc(timestamp.to_datetime)
  end

  extend self
end
