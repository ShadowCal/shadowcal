# frozen_string_literal: true

module TestCalendarApiHelper
  def refresh_access_token(_refresh_token); end

  def request_calendars(_access_token); end

  def request_events(_access_token, _my_email, _calendar_id); end

  def push_events(_access_token, _calendar_id, _events); end

  def push_event(_access_token, _calendar_id, _event); end

  def delete_event(_access_token, _calendar_id, _event_id); end

  def move_event(_access_token, _calendar_id, _event_id, _start_at, _end_at); end

  extend self
end
