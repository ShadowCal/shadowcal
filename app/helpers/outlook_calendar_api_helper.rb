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

  # def request_events(access_token, my_email, calendar_id)
  #   service = build_service(access_token)

  #   # Return each google api calendar as an ActiveRecord Calendar model
  #   events = get_calendar_events(service, calendar_id).map do |item|
  #     upsert_service_event_item(my_email, item)
  #   end

  #   # upsert_service_event_item sometimes returns nils, when an event doesn't
  #   # get made
  #   events.reject(&:nil?)
  # end

  # def get_event(access_token, my_email, calendar_id, event_id)
  #   service_event = build_service(access_token)
  #                   .get_event(
  #                     calendar_id,
  #                     event_id
  #                   )
  #                   .item

  #   upsert_service_event_item(my_email, service_event)
  # end

  # def push_events(access_token, calendar_id, events)
  #   return if events.empty?

  #   service = build_service(access_token)

  #   service.batch do |batch|
  #     events.each do |event|
  #       batch.insert_event(
  #         calendar_id,
  #         Google::Apis::CalendarV3::Event.new(
  #           summary:     event.name,
  #           description: event.description,
  #           start:       {
  #             date_time: event.start_at.iso8601
  #           },
  #           end:         {
  #             date_time: event.end_at.iso8601
  #           },
  #           visibility:  "public"
  #         )
  #       ) do |item|
  #         event.update_attributes external_id: item.id
  #       end
  #     end
  #   end
  # end

  # def push_event(access_token, calendar_id, event)
  #   service = build_service(access_token)

  #   item = service.insert_event(
  #     calendar_id,
  #     Google::Apis::CalendarV3::Event.new(
  #       summary:     event.name,
  #       description: event.description,
  #       start:       {
  #         date_time: event.start_at.iso8601
  #       },
  #       end:         {
  #         date_time: event.end_at.iso8601
  #       },
  #       visibility:  "public"
  #     )
  #   )

  #   event.update_attributes external_id: item.id
  # end

  # def delete_event(access_token, calendar_id, event_id)
  #   build_service(access_token)
  #     .delete_event(calendar_id, event_id)
  # end

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

  # private

  # TODO: Dedupe this from GoogleCalendarApiHelper
  def upsert_service_calendar_item(item)
    Calendar.where(external_id: item['Id']).first_or_create do |calendar|
      calendar.name = item['Name']
      calendar.time_zone = 'Etc/UTC'
    end
  end

  # def upsert_service_event_item(my_email, item)
  #   return if item.status == "cancelled"

  #   Event.where(
  #     external_id: item.id
  #   ).first_or_initialize.tap do |event|
  #     verb = event.new_record? ? "Created" : "Found"
  #     Rails.logger.debug "#{verb} #{DebugHelper.identify_event(event)}"

  #     item_start_date = service_date_to_active_support_date_time(item.start)
  #     item_end_date = service_date_to_active_support_date_time(item.end)

  #     event.name = item.summary
  #     event.start_at = item_start_date
  #     event.end_at = item_end_date
  #     event.source_event_id = DescriptionTagHelper.extract_source_event_id_tag_from_description(item.description)
  #     event.is_attending = (item.attendees || []).find{ |a| a.email == my_email }.try(:response_status).try(:==, 'accepted')
  #   end
  # end

  # def service_date_to_active_support_date_time(date)
  #   if date.date && date.time_zone
  #     ZoneHelper.from_date_str_and_zone_to_utc(date.date, date.time_zone)
  #   elsif date.date
  #     date.date.to_date
  #   else
  #     date.date_time
  #   end
  # end

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
