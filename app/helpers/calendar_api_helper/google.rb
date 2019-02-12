# frozen_string_literal: true

module CalendarApiHelper::Google
  TOKEN_URL = "https://accounts.google.com/o/oauth2/token"
  CLIENT_ID = ENV["GOOGLE_CLIENT_ID"]
  CLIENT_SECRET = ENV["GOOGLE_CLIENT_SECRET"]

  def refresh_access_token(refresh_token)
    url = URI(TOKEN_URL)

    params = {
      "refresh_token" => refresh_token,
      "client_id"     => CLIENT_ID,
      "client_secret" => CLIENT_SECRET,
      "grant_type"    => "refresh_token"
    }

    resp = Net::HTTP.post_form(url, params)

    JSON.parse(resp.body)
  end

  def request_calendars(access_token)
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    service.list_calendar_lists.items.map do |item|
      upsert_service_calendar_item(item)
    end
  end

  # TODO: use updated_min parameter or sync_token
  # http://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3/CalendarService#list_events-instance_method
  def request_events(access_token, my_email, calendar_id, calendar_zone)
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    events = get_calendar_events(service, calendar_id).map do |item|
      upsert_service_event_item(my_email, calendar_zone, item)
    end

    # upsert_service_event_item sometimes returns nils, when an event doesn't
    # get made
    events.reject(&:nil?)
  end

  def clear(access_token, calendar_id)
    service = build_service(access_token)

    get_calendar_events(service, calendar_id)
      .each { |event| delete_event(access_token, calendar_id, event.id) }
  end

  def push_events(access_token, calendar_id, events)
    return if events.empty?

    service = build_service(access_token)

    service.batch do |batch|
      events.each do |event|
        batch.insert_event(
          calendar_id,
          event_to_service_event_item(event, event.calendar.time_zone)
        ) do |item|
          event.update_attributes external_id: item.id
        end
      end
    end
  end

  def delete_event(access_token, calendar_id, event_id)
    build_service(access_token)
      .delete_event(calendar_id, event_id)
  end

  def move_event(access_token, calendar_id, event_id, start_at, end_at, is_all_day, in_time_zone)
    service = build_service(access_token)

    event = Event.new is_all_day: is_all_day, start_at: start_at, end_at: end_at

    service.patch_event(
      calendar_id,
      event_id,
      event_to_service_event_item_dates(event, in_time_zone)
    )
  end

  private

  def build_description_with_embedded_source_event_id(source_event_id)
    DescriptionTagHelper.add_source_event_id_tag_to_description(
      source_event_id,
      "The calendar owner is busy at this time with a private event.\n\n" \
      "This notice was created using shadowcal.com: Block personal events " \
      "off your work calendar without sharing details."
    )
  end

  def extract_source_event_id_from_description(description)
    DescriptionTagHelper.extract_source_event_id_tag_from_description(description)
  end

  def upsert_service_calendar_item(item)
    Calendar.where(external_id: item.id).first_or_create do |calendar|
      calendar.name = item.summary
      calendar.time_zone = item.time_zone
    end
  end

  def upsert_service_event_item(my_email, my_zone, item)
    return if item.status == "cancelled"

    Event.where(
      external_id: item.id
    ).first_or_initialize.tap do |event|
      verb = event.new_record? ? "Created" : "Found"
      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

      event.name = item.summary
      event.source_event_id = extract_source_event_id_from_description(item.description)

      item_start_date = service_date_to_active_support_date_time(item.start)
      item_end_date = service_date_to_active_support_date_time(item.end)
      event.start_at = item_start_date.in_time_zone(my_zone)
      event.end_at = item_end_date.in_time_zone(my_zone)

      event.is_attending = item&.creator&.self
      event.is_attending ||= (item.attendees || []).find{ |a| a.email == my_email }.try(:response_status).try(:==, 'accepted')

      event.is_all_day = item&.start&.date.nil? ? false : true

      event.is_blocking = item.transparency != 'transparent'
    end
  end

  def service_date_to_active_support_date_time(date)
    if date.date && date.time_zone
      ZoneHelper.from_date_str_and_zone_to_utc(date.date, date.time_zone)
    elsif date.date
      date.date.to_date
    else
      date.date_time
    end
  end

  def datetime_to_service_date(date, is_all_day)
    if is_all_day
      {
        date: date.strftime('%Y-%m-%d'),
        time_zone: date.time_zone.name,
      }
    else
      { date_time: date.iso8601 }
    end
  end

  def event_to_service_event_item(event, in_time_zone)
    Google::Apis::CalendarV3::Event.new(
      event_to_service_event_item_hash(event, in_time_zone)
    )
  end

  def event_to_service_event_item_dates(event, in_time_zone)
    Google::Apis::CalendarV3::Event.new(
      event_to_service_event_item_hash(event, in_time_zone, true)
    )
  end

  def event_to_service_event_item_hash(event, in_time_zone, just_dates = false)
    hash = {
      start: datetime_to_service_date(
        event.start_at.in_time_zone(in_time_zone),
        event.is_all_day
      ),
      end: datetime_to_service_date(
        event.end_at.in_time_zone(in_time_zone),
        event.is_all_day
      ),
    }

    unless just_dates
      hash.merge!(
        summary:     event.name,
        description: build_description_with_embedded_source_event_id(event.source_event_id),
        visibility:  "public"
      )
    end

    hash
  end

  def build_service(access_token)
    client = GoogleAccessToken.new access_token

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client
    service
  end

  def get_calendar_events(service, id)
    service
      .list_events(
        id,
        time_max: 1.month.from_now.iso8601,
        time_min: Time.zone.now.iso8601,
        single_events: true,
        max_results: 500,
        order_by: 'startTime'
      )
      .items
  end

  extend self
end
