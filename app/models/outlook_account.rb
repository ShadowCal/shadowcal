# frozen_string_literal: true

class OutlookAccount < RemoteAccount
  def request_calendars
    []
  end

  def refresh_token!
    update_attributes(
      access_token:     'not implemented',
      token_expires_at: 40.minutes.from_now
    )
  end
end
