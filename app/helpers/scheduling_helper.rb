# frozen_string_literal: true

module SchedulingHelper
  def timeslots(opts={})
    opts[:start_at] ||= Time.zone.now.beginning_of_day
    opts[:end_at] ||= Time.zone.now.end_of_day
    opts[:interval] ||= 30.minutes

    t = opts[:start_at].dup

    while t < opts[:end_at] do
      yield(t)
      t += opts[:interval]
    end
  end

  def timeslot_is_busy(timeslot, interval)
    @busy_times.any? { |e| e.start_at.in_time_zone(@time_zone) < (timeslot + interval).in_time_zone(@time_zone) and e.end_at.in_time_zone(@time_zone) > timeslot.in_time_zone(@time_zone) }
  end

  extend self
end
