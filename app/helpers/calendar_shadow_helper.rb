module CalendarShadowHelper
  def cast_from_to(from_calendar, to_calendar)
    update_calendar_events_cach(to_calendar)
    update_calendar_events_cach(from_calendar)

    cast_new_shadows(from_calendar, to_calendar)
  end

  private
  def update_calendar_events_cach(calendar)
    events = request_events_for_calendar(calendar)

    events.each do |event|
      event.calendar = calendar
      event.save!
    end

    calendar.reload
  end

  def cast_new_shadows(from_calendar, to_calendar)
    from_calendar.events.each do |event|
      next if event.shadow.exists?

      cast_shadow_of_event_on_calendar(event, to_calendar)
    end
  end

  def cast_shadow_of_event_on_calendar(source_event, to_calendar)
    shadow = shadow_of_event(source_event)
    shadow.calendar = to_calendar
    shadow.save
    create_remote_event(shadow)
  end

  def shadow_of_event(source_event)
    Event.where(source_event_id: source_event.id).first_or_create do |event|
      event.name = 'Busy'
      event.start_at = source_event.start_at
      event.end_at = source_event.end_at
    end
  end

  def create_remote_event(event)
    GoogleCalendarApiHelper.create_event(
      event.calendar.access_token,
      event.calendar.external_id,
      event.name,
      "SourceEvent##{event.source_event_id}",
      event.start_at,
      event.end_at,
    )
  end

  def request_events_for_calendar(calendar)
    GoogleCalendarApiHelper.request_events(
      calendar.access_token,
      calendar.external_id
    )
  end

  extend self
end
