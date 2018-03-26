# frozen_string_literal: true

module CalendarShadowHelper
  class ShadowHelperError < StandardError; end

  class CastingUnsyncdCalendars < ShadowHelperError
    def initialize(from_calendar_id, to_calendar_id)
      @from_calendar_id = from_calendar_id
      @to_calendar_id = to_calendar_id
      super("Casting between unsynced calendars")
    end
  end

  class ShadowVsSourceMismatchError < ShadowHelperError;
    def initialize(msg, event)
      @event = event
      super(msg)
    end
  end

  def cast_from_to(from_calendar, to_calendar)
    sync_pair_between = SyncPair.find_by_from_calendar_id_and_to_calendar_id(
      from_calendar.id,
      to_calendar.id
    )

    raise CastingUnsyncdCalendars.new(from_calendar.id, to_calendar.id) if sync_pair_between.nil?

    update_calendar_events_cache(to_calendar)
    update_calendar_events_cache(from_calendar)

    cast_new_shadows(from_calendar, to_calendar)
  end

  def destroy_shadow_of_event(source_event)
    unless source_event.source_event_id.nil?
      raise ShadowVsSourceMismatchError.new("Cannot delete the shadow of a shadow", source_event)
    end

    shadow = source_event.shadow_event

    begin
      unless shadow.external_id.blank?
        GoogleCalendarApiHelper.delete_event(
          shadow.access_token,
          shadow.calendar.external_id,
          shadow.external_id
        )
      end

      shadow.destroy
    rescue StandardError => e
      Rails.logger.debug [DebugHelper.identify_event(source_event), "Remote service fail? ", e].join(" ")
    end

    true
  end

  def push_shadow_of_event(source_event)
    unless source_event.source_event_id.nil?
      raise ShadowVsSourceMismatchError.new("Cannot create the shadow of a shadow", source_event)
    end

    return true unless source_event&.shadow_event&.external_id.nil?

    begin
      GoogleCalendarApiHelper.push_event(
        source_event.corresponding_calendar.access_token,
        source_event.corresponding_calendar.external_id,
        shadow_of_event(source_event)
      )
    rescue StandardError => e
      Rails.logger.debug [DebugHelper.identify_event(source_event), "Remote service fail? ", e].join(" ")
    end

    true
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
      .attending
      .without_shadows
      .tap { |result| Rails.logger.debug [from_calendar.name, to_calendar.name, "Need to create #{result.count} shadow(s)"].join "\t" }
      .find_in_batches(batch_size: batch_size) do |events_batch|
        cast_shadows_of_events_on_calendar(events_batch, to_calendar)
      end
  end

  def cast_shadows_of_events_on_calendar(events_batch, to_calendar)
    Event.transaction do
      shadows = events_batch
                .reject(&:outside_work_hours)
                .map { |source_event| shadow_of_event(source_event) }

      Event.where(id: shadows).update_all(calendar_id: to_calendar.id)

      create_remote_events(to_calendar, shadows)
    end
  end

  def shadow_of_event(source_event)
    if source_event.corresponding_calendar.nil?
      msg = "Cannot find or create the shadow of an event" \
            " which belongs to a calendar that is not casting" \
            " a shadow."

      msg = [DebugHelper.identify_event(source_event), msg].join("\t")

      Rails.logger.debug msg

      raise ShadowHelperError, msg
    end

    Event.where(source_event_id: source_event.id).first_or_initialize{ |event|
      event.name = "(Busy)"
      event.start_at = source_event.start_at
      event.end_at = source_event.end_at
      event.calendar_id = source_event.corresponding_calendar.id
      event.is_attending = source_event.is_attending
    }.tap { |event|
      verb = event.new_record? ? "Created" : "Found"

      event.save!

      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"
    }
  end

  def create_remote_events(calendar, events)
    GoogleCalendarApiHelper.push_events(
      calendar.access_token,
      calendar.external_id,
      events
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
