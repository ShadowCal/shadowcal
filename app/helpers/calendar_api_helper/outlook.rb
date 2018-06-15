# frozen_string_literal: true

module CalendarApiHelper::Outlook
  EVENT_FIELDS = %w{Id Subject BodyPreview Start End IsAllDay IsCancelled ShowAs}.freeze
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

  def request_events(access_token, my_email, calendar_id)
    resp = client.get_calendar_view(
      access_token,
      Time.now.utc,
      1.month.from_now.utc,
      calendar_id,
      EVENT_FIELDS
    )

    # Return each google api calendar as an ActiveRecord Calendar model
    events = resp['value'].map do |item|
      upsert_service_event_item(my_email, item)
    end

    # upsert_service_event_item sometimes returns nils, when an event doesn't
    # get made
    events.reject(&:nil?)
  end

  def push_events(access_token, calendar_id, events)
    return [] if events.empty?

    events.map{ |e| push_event(access_token, calendar_id, e) }
  end

  def delete_event(access_token, event_id)
    client.delete_event(access_token, event_id)
  end

  def move_event(access_token, event_id, start_at, end_at)
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
          'DateTime' => event.start_at.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
        'End' => {
          'DateTime' => event.end_at.strftime('%Y-%m-%dT%H:%M:%S'),
          'TimeZone' => 'Etc/GMT',
        },
        'Subject' => event.name,
        'Sensitivity' => 'normal',
        'ShowAs' => event.is_attending ? 'busy' : 'free',
        'IsCancelled' => false,
        'ResponseStatus' => {
          'Response' => 'Organizer',
        },
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

  def upsert_service_event_item(_my_email, item)
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
    end
  end

  def service_date_to_active_support_date_time(date)
    ZoneHelper.from_zoneless_timestamp_and_zone_to_utc(date['DateTime'], date['TimeZone'])
  end

  extend self
end
