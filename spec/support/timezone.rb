# spec/support/timezone.rb
module TimeZoneHelpers
  extend ActiveSupport::Concern

  def self.random_timezone
    offsets = ActiveSupport::TimeZone.all.group_by(&:formatted_offset)
    zones = offsets[offsets.keys.sample] # Random offset to better vary the time zone differences
    zones.sample # Random zone from the offset (can be just 1st, but let's do random)
  end

  def self.randomise_timezone!
    Time.zone = random_timezone
    puts "Current rand time zone: #{Time.zone}. Repro: Time.zone = #{Time.zone.name.inspect}"
  end


  module ClassMethods
    def context_with_time_zone(zone, &block)
      context ", in the time zone #{zone.to_s}," do
        before { @prev_time_zone = Time.zone; Time.zone = zone }
        after { Time.zone = @prev_time_zone }
        self.instance_eval(&block)
      end
    end

    def across_time_zones(options, &block)
      options.assert_valid_keys(:step)
      step_seconds = options.fetch(:step)
      offsets = ActiveSupport::TimeZone.all.group_by(&:utc_offset).sort_by {|off, zones| off }
      last_offset = -10.days # far enough in the past
      offsets.each do |(current_offset, zones)|
        if (current_offset - last_offset) >= step_seconds
          last_offset = current_offset
          context_with_time_zone(zones.sample, &block)
        end
      end
    end

  end
end

RSpec.configure do |config|
  config.before(:suite) do
    TimeZoneHelpers.randomise_timezone!
  end
  config.include TimeZoneHelpers
end
