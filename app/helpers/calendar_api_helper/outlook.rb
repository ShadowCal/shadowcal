# frozen_string_literal: true

module CalendarApiHelper::Outlook
  EVENT_FIELDS = %w{Id Subject Body Start End IsAllDay IsCancelled ShowAs ResponseStatus}.freeze
  CALENDAR_FIELDS = %w{Id Name}.freeze

  TOKEN_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  CLIENT_ID = ENV["OUTLOOK_APP_ID"]
  CLIENT_SECRET = ENV["OUTLOOK_SECRET"]

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

  def client
    RubyOutlook::Client.new
  end

  def request_calendars(access_token)
    # Return each google api calendar as an ActiveRecord Calendar model
    resp = client.get_calendars(access_token, 10, 1, CALENDAR_FIELDS)

    resp["value"].map do |item|
      # TODO skip read only calendars
      upsert_service_calendar_item(item)
    end
  end

  def request_events(access_token, my_email, calendar_id, _my_zone)
    resp = client.get_calendar_view(
      access_token,
      Time.zone.now.utc,
      1.month.from_now.utc,
      calendar_id,
      EVENT_FIELDS
    )

    time_zone = Calendar.joins(:remote_account)
                        .where('remote_accounts.email = ? AND calendars.external_id=?', my_email, calendar_id)
                        .pluck(:time_zone)
                        .first

    # Return each google api calendar as an ActiveRecord Calendar model
    events = resp['value'].map do |item|
      upsert_service_event_item(my_email, item, time_zone)
    end

    # upsert_service_event_item sometimes returns nils, when an event doesn't
    # get made
    events.reject(&:nil?)
  end

  def push_events(access_token, calendar_id, events)
    return [] if events.empty?

    events.map{ |e| push_event(access_token, calendar_id, e) }
  end

  def clear(access_token, calendar_id)
    resp = client.get_calendar_view(
      access_token,
      Time.zone.now.utc,
      1.month.from_now.utc,
      calendar_id,
      EVENT_FIELDS
    )

    resp['value'].each { |event| puts event.inspect; delete_event(access_token, event['Id']) }
  end

  def delete_event(access_token, event_id)
    client.delete_event(access_token, event_id)
  end

  def move_event(access_token, _calendar_id, event_id, start_at, end_at, _is_all_day, _in_time_zone)
    client.update_event(
      access_token,
      {
        'Start' => {
          'DateTime' => start_at.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
        'End' => {
          'DateTime' => end_at.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
      },
      event_id
    )
  end

  private

  def push_event(access_token, calendar_id, event)
    resp = client.create_event(
      access_token,
      {
        'Body' => {
          'ContentType' => 'Text',
          'Content' => build_description_with_embedded_source_event_id(event.source_event_id),
        },
        'Start' => {
          'DateTime' => event.start_at.utc.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
        'End' => {
          'DateTime' => event.end_at.utc.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
        'Subject' => event.name,
        'Sensitivity' => 'normal',
        'ShowAs' => event.is_attending ? 'busy' : 'free',
        'IsCancelled' => false,
        'ResponseStatus' => {
          'Response' => 'Organizer',
        },
        'IsAllDay' => event.is_all_day
      },
      calendar_id
    )

    event.tap{ |e| e.update_attributes external_id: resp['Id'] unless resp.nil? }
  end

  # TODO: Dedupe this from CalendarApiHelper::Google
  def build_description_with_embedded_source_event_id(source_event_id)
    DescriptionTagHelper.add_source_event_id_tag_to_description(
      source_event_id,
      "The calendar owner is busy at this time with a private event.\n\n" \
      "This notice was created using shadowcal.com: Block personal events " \
      "off your work calendar without sharing details."
    )
  end

  # TODO: Dedupe this from CalendarApiHelper::Google
  def extract_source_event_id_from_description(description)
    DescriptionTagHelper.extract_source_event_id_tag_from_description(description)
  end

  # TODO: Dedupe this from CalendarApiHelper::Google
  def upsert_service_calendar_item(item)
    Calendar.where(external_id: item['Id']).first_or_create do |calendar|
      calendar.name = item['Name']
      # calendar.time_zone = 'Etc/UTC'
    end
  end

  def upsert_service_event_item(_my_email, item, time_zone)
    return if item['IsCancelled']

    Event.where(
      external_id: item['Id']
    ).first_or_initialize.tap do |event|
      verb = event.new_record? ? "Created" : "Found"
      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

      event.name = item['Subject']
      event.start_at = service_date_to_active_support_date_time(item['Start'])
      event.end_at = service_date_to_active_support_date_time(item['End'])
      event.source_event_id = extract_source_event_id_from_description(item['Body']['Content'])
      event.is_attending = ['Organizer', 'TentativelyAccepted', 'Accepted'].include?(item['ResponseStatus']['Response'])
      event.is_blocking = ['free', 'tentative', 'unknown'].exclude?(item['ShowAs'])

      if item['IsAllDay']
        event.is_all_day = true

        # Outlook tells as all day events start and end at 00:00:00 UTC,
        # regardless of the timezone of the calendar, but we want our UTC
        # timestamps on each event to be acurate so we manually shift all-day
        # events' times based on the offset
        event.start_at = ZoneHelper.from_zoneless_timestamp_and_zone_to_utc(item['Start']['DateTime'], time_zone)
        event.end_at = ZoneHelper.from_zoneless_timestamp_and_zone_to_utc(item['End']['DateTime'], time_zone)

        # Outlook returns end_at for all-day events as 00:00:00 the next day.
        # We want 23:59:59 at the end of the day of the event
        event.end_at -= 1.second
      end
    end
  end

  def service_date_to_active_support_date_time(date)
    ZoneHelper.from_zoneless_timestamp_and_zone_to_utc(date['DateTime'], date['TimeZone'])
  end

  extend self
end
