# frozen_string_literal: true

class GoogleAccount < RemoteAccount
  def request_calendars
    GoogleCalendarApiHelper.request_calendars(access_token)
  end

  def refresh_token!
    resp = GoogleCalendarApiHelper.refresh_access_token(refresh_token)
    update_attributes(
      access_token:     resp["access_token"],
      token_expires_at: resp["expires_in"].to_i.seconds.from_now
    )
  end
end
