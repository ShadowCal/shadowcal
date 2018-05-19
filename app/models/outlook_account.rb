# frozen_string_literal: true

class OutlookAccount < RemoteAccount
  def request_calendars
    OutlookCalendarApiHelper.request_calendars(access_token)
  end

  def refresh_token!
    update_attributes(
      access_token:     'not implemented',
      token_expires_at: 40.minutes.from_now
    )
  end
end
