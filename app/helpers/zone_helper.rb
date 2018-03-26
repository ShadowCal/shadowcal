# frozen_string_literal: true

module ZoneHelper
  def from_date_str_and_zone_to_utc(date_str, zone_str)
    ActiveSupport::TimeZone.new(zone_str).local_to_utc(date_str.to_date.to_datetime)
  end

  extend self
end
