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

  def cast_new_shadows(from_calendar, to_calendar, batch_size=100)
    from_calendar.events.without_shadows.find_in_batches(batch_size: batch_size) do |events_batch|
      cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    end
  end

  def cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    Event.transaction do
      shadows = events_batch.map{ |source_event| shadow_of_event(source_event) }

      Event.where({id: shadows}).update_all({calendar_id: to_calendar.id})

      create_remote_events(to_calendar, shadows)
    end
  end

  def shadow_of_event(source_event)
    Event.where(source_event_id: source_event.id).first_or_create do |event|
      event.name = 'Busy'
      event.start_at = source_event.start_at
      event.end_at = source_event.end_at
    end
  end

  def create_remote_events(calendar, events)
    GoogleCalendarApiHelper.create_events(
      calendar.access_token,
      calendar.external_id,
      events
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
