# frozen_string_literal: true

module CalendarViewHelper
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

  extend self
end
