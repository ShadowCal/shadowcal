module CalendarShadowHelper
  def cast_from_to(from_calendar, to_calendar)
    puts "Casting from #{from_calendar.name} to #{to_calendar.name}"

    update_calendar_events_cach(to_calendar)
    update_calendar_events_cach(from_calendar)

    cast_new_shadows(from_calendar, to_calendar)
  end

  private
  def update_calendar_events_cach(calendar)
    puts "Caching events of #{calendar.name}"

    events = request_events_for_calendar(calendar)

    puts "Got #{events.length} events from #{calendar.name}"

    events.each do |event|
      puts "Saving #{event.name}"
      event.calendar = calendar
      event.save!
    end

    calendar.reload
  end

  def cast_new_shadows(from_calendar, to_calendar, batch_size=100)
    puts "From calendar (#{from_calendar.name}) has #{from_calendar.events.count} events"
    puts "Of these, #{from_calendar.events.without_shadows.count} need shadows"
    from_calendar.events.without_shadows.find_in_batches(batch_size: batch_size) do |events_batch|
      cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    end
  end

  def cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    puts "Casting shadows of #{events_batch.length} events on #{to_calendar.name}"
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
