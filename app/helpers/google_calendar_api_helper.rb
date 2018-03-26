# frozen_string_literal: true

module GoogleCalendarApiHelper
  def refresh_access_token(refresh_token)
    url = URI("https://accounts.google.com/o/oauth2/token")

    params = {
      "refresh_token" => refresh_token,
      "client_id"     => ENV["GOOGLE_CLIENT_ID"],
      "client_secret" => ENV["GOOGLE_CLIENT_SECRET"],
      "grant_type"    => "refresh_token"
    }

    resp = Net::HTTP.post_form(url, params)

    JSON.parse(resp.body)
  end

  def request_calendars(access_token)
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    service.list_calendar_lists.items.map do |item|
      service_calendar_item_to_calendar_model(item)
    end
  end

  # TODO: use updated_min parameter or sync_token
  # http://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3/CalendarService#list_events-instance_method
  def request_events(access_token, external_id)
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    get_calendar_events(service, external_id).map do |item|
      service_event_item_to_event_model(item)
    end
  end

  def create_events(access_token, calendar_id, events)
    service = build_service(access_token)

    service.batch do |batch|
      events.map do |event|
        batch.insert_event(
          calendar_id,
          Google::Apis::CalendarV3::Event.new(event)
        )
      end
    end
  end

  def move_event(access_token, calendar_id, event_id, start_at, end_at)
    service = build_service(access_token)

    service.patch_event(
      calendar_id,
      event_id,
      Google::Apis::CalendarV3::Event.new(
        start: {
          date_time: start_at.iso8601
        },
        end: {
          date_time: end_at.iso8601
        },
      )
    )
  end

  private

  def service_calendar_item_to_calendar_model(item)
    Calendar.where(external_id: item.id).first_or_create do |calendar|
      calendar.name = item.summary
    end
  end

  def service_event_item_to_event_model(item)
    Event.where(
      external_id: item.id
    ).first_or_initialize do |event|
      verb = event.new_record? ? "Created" : "Found"
      Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

      item_start_date = item.start.date || item.start.date_time
      item_end_date = item.end.date || item.end.date_time

      event.name = item.summary
      event.start_at = item_start_date
      event.end_at = item_end_date
      event.source_event_id = item.description.try(:[], /SourceEvent#(0-9)+/, 1)
    end
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
        time_min: Time.now.iso8601
      )
      .items
      .reject { |item| item.transparency == "transparent" }
  end

  extend self
end
