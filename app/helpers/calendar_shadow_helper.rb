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

  class ShadowHelperErrorWithEvent < ShadowHelperError
    def initialize(msg, event)
      @event = event
      super(msg)
    end
  end

  class ShadowOfShadowError < ShadowHelperErrorWithEvent; end
  class ShadowWithoutPairError < ShadowHelperErrorWithEvent; end

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
    shadow = shadow_of_event(source_event)

    begin
      shadow.remote_account.delete_event(shadow) unless shadow.external_id.blank?
    rescue StandardError => e
      Rails.logger.debug [DebugHelper.identify_event(source_event), "Remote service fail? ", e].join(" ")
      raise
    end

    shadow.destroy

    nil
  end

  def push_shadow_of_event(source_event)
    cast_shadows_of_events_on_calendar([source_event], source_event.corresponding_calendar)
  end

  private

  def update_calendar_events_cache(calendar)
    events = calendar.request_events

    events.each do |event|
      event.calendar = calendar
      event.save!
    end

    calendar.reload
  end

  def events_needing_shadows(from_calendar)
    from_calendar
      .events
      .attending
      .blocking
      .without_shadows
      .reject(&:outside_work_hours)
  end

  def cast_new_shadows(from_calendar, to_calendar, batch_size = 100)
    events_needing_shadows(from_calendar)
      .tap { |result| Rails.logger.debug [from_calendar.name, to_calendar.name, "Need to create #{result.count} shadow(s)"].join "\t" }
      .in_groups_of(batch_size, false).each do |events_batch|
        cast_shadows_of_events_on_calendar(events_batch, to_calendar)
      end
  end

  def cast_shadows_of_events_on_calendar(events, to_calendar)
    shadows = []

    events
      .select { |source_event| source_event.shadow_event&.external_id.nil? }
      .each do |source_event|
        begin
          shadows << shadow_of_event(source_event)
        rescue ShadowHelperError => e
          Rails.logger.debug [DebugHelper.identify_event(source_event), e.message].join("\t")
          raise
        end
      end

    return if shadows.empty?

    Event.transaction do
      Event.where(id: shadows).update_all(calendar_id: to_calendar.id)

      to_calendar.push_events(shadows)
    end
  end

  def shadow_of_event(source_event)
    unless source_event.source_event_id.nil?
      raise ShadowOfShadowError.new("Cannot create the shadow of a shadow", source_event)
    end

    if source_event.corresponding_calendar.nil?
      raise ShadowWithoutPairError.new(
        "Cannot find or create the shadow of an event" \
        " which belongs to a calendar that is not casting" \
        " a shadow.",
        source_event
      )
    end

    Event.where(source_event_id: source_event.id).first_or_initialize{ |event|
      event.name = "(Busy)"
      event.start_at = source_event.start_at
      event.end_at = source_event.end_at
      event.calendar_id = source_event.corresponding_calendar.id
      event.is_attending = source_event.is_attending
      event.is_blocking = source_event.is_blocking
      event.is_all_day = source_event.is_all_day
    }.tap { |event|
      verb = event.new_record? ? "Created" : "Found"

      event.save!

      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"
    }
  end

  extend self
end
