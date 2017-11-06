# frozen_string_literal: true

module CalendarShadowHelper
  def cast_from_to(from_calendar, to_calendar)
    update_calendar_events_cache(to_calendar)
    update_calendar_events_cache(from_calendar)

    cast_new_shadows(from_calendar, to_calendar)
  end

  private

  def update_calendar_events_cache(calendar)
    events = request_events_for_calendar(calendar)

    events.each do |event|
      event.calendar = calendar
      event.save!
    end

    calendar.reload
  end

  def cast_new_shadows(from_calendar, to_calendar, batch_size = 100)
    from_calendar
      .events
      .without_shadows
      .tap { |result| Rails.logger.debug [from_calendar.name, to_calendar.name, "Need to create #{result.count} shadow(s)"].join "\t" }
      .find_in_batches(batch_size: batch_size) do |events_batch|
        cast_shadows_of_events_on_calendar(events_batch, to_calendar)
      end
  end

  def cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    Event.transaction do
      shadows = events_batch.map { |source_event| shadow_of_event(source_event) }

      Event.where(id: shadows).update_all(calendar_id: to_calendar.id)

      create_remote_shadows(to_calendar, shadows)
    end
  end

  def shadow_of_event(source_event)
    Event.where(source_event_id: source_event.id).first_or_initialize do |event|
      event.name = source_event.name
      event.start_at = source_event.start_at
      event.end_at = source_event.end_at

      verb = event.new_record? ? "Created" : "Found"
      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

      event.save!
    end
  end

  def create_remote_shadows(calendar, events)
    GoogleCalendarApiHelper.create_events(
      calendar.access_token,
      calendar.external_id,
      events.map do |event|
        {
          summary:     "(Busy)",
          description: DescriptionTagHelper.add_source_event_id_tag_to_description(
            "The calendar owner is busy at this time with a private event.\n\n" \
            "This notice was created using shadowcal.com: Block personal events " \
            "off your work calendar without sharing details."
          ),
          start:       {
            date_time: event.start_at.iso8601
          },
          end:         {
            date_time: event.end_at.iso8601
          },
          visibility:  "public"
        }
      end
    )
  end

  def request_events_for_calendar(calendar)
    GoogleCalendarApiHelper.request_events(
      calendar.access_token,
      calendar.google_account.email,
      calendar.external_id
    )
  end
  extend self
end
