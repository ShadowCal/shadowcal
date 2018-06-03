# frozen_string_literal: true

class RemoteAccount < ActiveRecord::Base
  belongs_to :user
  has_many :calendars

  after_create :queue_request_calendars, unless: :skip_callbacks

  after_initialize :refresh_token!, if: :should_refresh_token?

  scope :to_be_refreshed, lambda {
    where(
      "token_expires_at IS NOT NULL AND " \
      "refresh_token IS NOT NULL AND " \
      "token_expires_at < ?", 20.minutes.from_now
    )
  }

  def self.calendar_helper
    raise NotImplementedError, "class#calendar_helper must be implemented by a subclass"
  end

  def request_calendars
    self.class.calendar_helper.request_calendars(access_token)
  end

  def request_events(calendar_id)
    self.class.calendar_helper.request_events(access_token, email, calendar_id)
  end

  def get_event(calendar_id, event_id)
    self.class.calendar_helper.get_event(access_token, email, calendar_id, event_id)
  end

  def push_events(calendar_id, events)
    self.class.calendar_helper.push_events(access_token, calendar_id, events)
  end

  def push_event(calendar_id, event)
    self.class.calendar_helper.push_event(access_token, calendar_id, event)
  end

  def delete_event(event)
    self.class.calendar_helper.delete_event(
      event.access_token,
      event.calendar.external_id,
      event.external_id
    )
  end

  def move_event(calendar_id, event_id, start_at, end_at)
    self.class.calendar_helper.move_event(access_token, calendar_id, event_id, start_at, end_at)
  end


  private

  def queue_request_calendars
    Delayed::Job.enqueue RequestCalendarsJob.new(id), queue: :request_calendars
  end

  def refresh_token!
    resp = self.class.calendar_helper.refresh_access_token(refresh_token)
    attrs = {}
    attrs[:access_token] = resp["access_token"]
    attrs[:token_expires_at] = resp["expires_in"].to_i.seconds.from_now
    attrs[:refresh_token] = resp["refresh_token"] if resp["refresh_token"]
    update_attributes(attrs)
  end

  def should_refresh_token?
    return false if skip_callbacks
    token_expires_at < Time.current unless (token_expires_at.nil? || refresh_token.blank?)
  end
end
