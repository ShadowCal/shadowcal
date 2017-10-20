module GoogleCalendarApiHelper
  def request_calendars(access_token)
    puts "Requesting calendars using token: #{access_token}"
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    service.list_calendar_lists.items.map do |item|
      puts "Found Calendar #{item.inspect}"
      service_calendar_item_to_calendar_model(item)
    end
  end

  # TODO: use updated_min parameter or sync_token
  # http://www.rubydoc.info/github/google/google-api-ruby-client/Google/Apis/CalendarV3/CalendarService#list_events-instance_method
  def request_events(access_token, external_id)
    puts "Requesting events of calendar##{external_id} using token: #{access_token}"
    service = build_service(access_token)

    # Return each google api calendar as an ActiveRecord Calendar model
    get_calendar_events(service, external_id).map do |item|
      puts "Found Event #{item.inspect}"
      service_event_item_to_event_model(item)
    end
  end

  def create_events(access_token, calendar_id, events)
    service = build_service(access_token)

    puts "Creating #{events.length} events on calendar #{calendar_id} with token #{access_token}"

    service.batch do |service|
      events.map do |event|
        puts "Preparing batch entry to create event #{event.inspect}"

        service.insert_event(
          calendar_id,
          Google::Apis::CalendarV3::Event.new({
            summary: event.name,
            description: event.description,
            start: {
              date_time: event.start_at.iso8601
            },
            end: {
              date_time: event.end_at.iso8601
            },
            visibility: 'private'
          })
        )
      end

      puts "Time to execute batch..."
    end
  end

  private
  def service_calendar_item_to_calendar_model(item)
    Calendar.where(external_id: item.id).first_or_create do |calendar|

      puts "Converting calendar #{item.inspect} into #{calendar.inspect}"
      calendar.name = item.summary
      puts "Result: #{calendar.inspect}"
    end
  end

  def service_event_item_to_event_model(item)
    puts "Finding or creating event from #{item.inspect}"
    Event.where(
      external_id: item.id
    ).first_or_create do |event|
      event.name = item.summary
      event.start_at = item.start.date || item.start.date_time
      event.end_at = item.end.date || item.end.date_time
      event.source_event_id = item.description.try(:[], /SourceEvent#(0-9)+/, 1)

      puts "Creating: #{event.inspect}"
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
  end

  extend self
end
