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

  def request_calendars
    raise NotImplementedError, "#request_calendars must be implemented by a subclass (based on type)"
  end

  private

  def queue_request_calendars
    Delayed::Job.enqueue RequestCalendarsJob.new(id), queue: :request_calendars
  end

  def refresh_token!
    raise NotImplementedError, "#refresh_token! must be implemented by a subclass (based on type)"
  end

  def should_refresh_token?
    return false if skip_callbacks
    token_expires_at < Time.current unless token_expires_at.nil? || refresh_token.blank?
  end
end
