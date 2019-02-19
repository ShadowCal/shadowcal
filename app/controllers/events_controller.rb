# frozen_string_literal: true

class EventsController < ApplicationController
  def new
    @user = User.find params.require(:user_id)

    @time_zone = @user.scheduling_calendar.time_zone
    @work_day_start = ZoneHelper.from_zoneless_timestamp_and_zone_to_utc('09:00:00', @time_zone)
    @work_day_end = ZoneHelper.from_zoneless_timestamp_and_zone_to_utc('17:00:00', @time_zone)
    @interval = 30.minutes
    @first_day = @work_day_start.beginning_of_day

    @busy_times = @user.scheduling_calendar.events.map do |e|
      {
        start: e.start_at,
        end: e.end_at,
        title: e.name,
        allDay: e.is_all_day
      }
    end
  end
end
