# frozen_string_literal: true

module OutlookCalendarApiHelper
  # def refresh_access_token(refresh_token)
  #   url = URI("https://accounts.google.com/o/oauth2/token")

  #   params = {
  #     "refresh_token" => refresh_token,
  #     "client_id"     => ENV["GOOGLE_CLIENT_ID"],
  #     "client_secret" => ENV["GOOGLE_CLIENT_SECRET"],
  #     "grant_type"    => "refresh_token"
  #   }

  #   resp = Net::HTTP.post_form(url, params)

  #   JSON.parse(resp.body)
  # end

  def client
    RubyOutlook::Client.new
  end

  def request_calendars(access_token)
    # Return each google api calendar as an ActiveRecord Calendar model
    resp = client.get_calendars(access_token, 10, 1, %w{Id Name})

    resp["value"].map do |item|
      # TODO skip read only calendars
      upsert_service_calendar_item(item)
    end
  end

  def request_events(access_token, my_email, calendar_id)
    resp = client.get_calendar_view(
      access_token,
      DateTime.now.utc,
      1.month.from_now.to_datetime.utc,
      calendar_id,
      %w{Id Subject BodyPreview Start End IsAllDay IsCancelled ShowAs}
    )

    # Return each google api calendar as an ActiveRecord Calendar model
    events = resp['value'].map do |item|
      upsert_service_event_item(my_email, item)
    end

    # upsert_service_event_item sometimes returns nils, when an event doesn't
    # get made
    events.reject(&:nil?)
  end

  # def get_event(access_token, my_email, calendar_id, event_id)
  #   service_event = build_service(access_token)
  #                   .get_event(
  #                     calendar_id,
  #                     event_id
  #                   )
  #                   .item

  #   upsert_service_event_item(my_email, service_event)
  # end

  def push_events(access_token, calendar_id, events, batch_size=20)
    return [] if events.empty?

    events.tap do |e|
      e.each_slice(batch_size).each do |batch|
        resps = client.batch_create_events(
          access_token,
          batch.map { |event| {
            'Body' => {
              'ContentType' => 0,
              'Content' => event.description,
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
            'Sensitivity' => 0,
            'ShowAs' => if event.is_attending then 2 else 0 end,
            'Type' => 0,
            'IsCancelled' => false,
          } },
          calendar_id
        )

        resps.each_with_index do |resp, i|
          batch[i].update_attributes external_id: resp['Id'] unless resp.nil?
        end
      end
    end
  end

  def push_event(access_token, calendar_id, event)
    push_events(access_token, calendar_id, [event])
  end

  def delete_event(access_token, event_id)
    client.delete_event(access_token, event_id)
  end

  # def move_event(access_token, calendar_id, event_id, start_at, end_at)
  #   service = build_service(access_token)

  #   service.patch_event(
  #     calendar_id,
  #     event_id,
  #     Google::Apis::CalendarV3::Event.new(
  #       start: {
  #         date_time: start_at.iso8601
  #       },
  #       end: {
  #         date_time: end_at.iso8601
  #       },
  #     )
  #   )
  # end

  private

  # TODO: Dedupe this from GoogleCalendarApiHelper
  def upsert_service_calendar_item(item)
    Calendar.where(external_id: item['Id']).first_or_create do |calendar|
      calendar.name = item['Name']
      # calendar.time_zone = 'Etc/UTC'
    end
  end

  def upsert_service_event_item(my_email, item)
    return if item['IsCancelled']
    return if item['ShowAs'] < 2

    Event.where(
      external_id: item['Id']
    ).first_or_initialize.tap do |event|
      verb = event.new_record? ? "Created" : "Found"
      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

      event.name = item['Subject']
      event.start_at = service_date_to_active_support_date_time(item['Start'])
      event.end_at = service_date_to_active_support_date_time(item['End'])
      event.source_event_id = DescriptionTagHelper.extract_source_event_id_tag_from_description(item['Body']['Content'])
      event.is_attending = ['Organizer', 'TentativelyAccepted', 'Accepted'].include?(item['ResponseStatus']['Response'])
    end
  end

  def service_date_to_active_support_date_time(date)
    ZoneHelper.from_zoneless_timestamp_and_zone_to_utc(date['DateTime'], date['TimeZone'])
  end

  # def get_calendar_events(service, id)
  #   service
  #     .list_events(
  #       id,
  #       time_max: 1.month.from_now.iso8601,
  #       time_min: Time.now.iso8601
  #     )
  #     .items
  #     .reject { |item| item.transparency == "transparent" }
  # end

  extend self
end
