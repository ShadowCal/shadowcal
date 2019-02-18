# frozen_string_literal: true

class RemoteAccount < ActiveRecord::Base
  belongs_to :user
  has_many :calendars, dependent: :destroy

  after_create :queue_request_calendars, unless: :skip_callbacks

  after_initialize :refresh_token!, if: :should_refresh_token?

  scope :to_be_refreshed, lambda {
    where(
      "token_expires_at IS NOT NULL AND " \
      "refresh_token IS NOT NULL AND " \
      "token_expires_at < ?", 24.hours.from_now
    )
  }

  after_save :ensure_refresh_token!, unless: :skip_callbacks

  class SyncingError < StandardError
    def initialize(msg, remote_account)
      pii_keys = %I{email access_token token_secret refresh_token}
      clean_keys = RemoteAccount.column_names.map(&:to_sym) - pii_keys
      @remote_account_data = remote_account.attributes.symbolize_keys.slice(*clean_keys)
      super(msg)
    end
  end

  class SavedWithoutRefreshToken < SyncingError
    def initialize(remote_account)
      super("RemoteAccount should always have a refresh token, or we'll run into sync issues in the future", remote_account)
    end
  end

  def self.calendar_helper
    raise NotImplementedError, "class#calendar_helper must be implemented by a subclass"
  end

  def default_calendar
    calendars.where('calendars.name IN (?)', ['Personal']).first || calendars.where('calendars.name = ?', email).first
  end

  def request_calendars
    self.class.calendar_helper.request_calendars(access_token)
  end

  def request_events(calendar_id, calendar_zone)
    self.class.calendar_helper.request_events(access_token, email, calendar_id, calendar_zone)
  end

  def push_events(calendar_id, events)
    self.class.calendar_helper.push_events(access_token, calendar_id, events)
  end

  def delete_event(event)
    self.class.calendar_helper.delete_event(
      event.access_token,
      event.calendar.external_id,
      event.external_id
    )
  end

  def move_event(calendar_id, event_id, start_at, end_at, is_all_day, in_time_zone)
    self.class.calendar_helper.move_event(access_token, calendar_id, event_id, start_at, end_at, is_all_day, in_time_zone)
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

    token_expires_at < Time.zone.now unless token_expires_at.nil? || refresh_token.blank?
  end

  def ensure_refresh_token!
    Rollbar.error(SavedWithoutRefreshToken.new(self)) if refresh_token.blank?
  end
end
