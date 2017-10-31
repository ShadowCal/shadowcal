# frozen_string_literal: true

class GoogleAccount < ActiveRecord::Base
  belongs_to :user
  has_many :calendars

  after_create :fetch_calendars, unless: lambda { Rails.env.test? }

  after_initialize :refresh_token!, if: :should_refresh_token?

  scope :to_be_refreshed, lambda {
    where(
      "token_expires_at IS NOT NULL AND " \
      "refresh_token IS NOT NULL AND " \
      " token_expires_at < ?", 20.minutes.from_now
    )
  }

  private

  def fetch_calendars
    self.calendars = GoogleCalendarApiHelper.request_calendars(access_token)
  end
  handle_asynchronously :fetch_calendars

  def refresh_token!
    resp = GoogleCalendarApiHelper.refresh_access_token(refresh_token)
    update_attributes(
      access_token:     resp["access_token"],
      token_expires_at: resp["expires_in"].to_i.seconds.from_now
    )
  end

  def should_refresh_token?
    token_expires_at < Time.current unless token_expires_at.nil? || refresh_token.blank?
  end
end
