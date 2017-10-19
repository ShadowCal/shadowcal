module GoogleCalendarApiHelper
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

  def create_event(access_token, calendar_id, summary, description, start_at, end_at)
    service = build_service(access_token)

    event = Google::Apis::CalendarV3::Event.new({
      summary: summary,
      description: description,
      start: {
        date_time: start_at
      },
      end: {
        date_time: end_at
      },
      visibility: 'private'
    })

    service.insert_event(calendar_id, event)
  end

  private
  def service_calendar_item_to_calendar_model(item)
    Calendar.where(external_id: item.id).first_or_create do |calendar|
      calendar.name = item.summary
    end
  end

  def service_event_item_to_event_model(item)
    Event.where(
      source_event_id: item.description[/SourceEvent#(0-9)+/, 1]
    ).first_or_create do |event|
      event.name = item.summary
      event.start_at = item.start
      event.end_at = item.end
      event.external_id = item.id
    end
  end

  def build_service(access_token)
    client = AccessToken.new access_token

    service = Google::Apis::CalendarV3::CalendarService.new

    service.authorization = client
  end

  def get_calendar_events(service, id)
    service
      .list_events(
        calendar.external_id,
        time_max: 1.month.from_now,
        time_min: Time.now
      )
      .items
  end
end
