# frozen_string_literal: true

class GoogleAccount < RemoteAccount
  def self.calendar_helper
    CalendarApiHelper::Google
  end

  def refresh_token!
    resp = self.class.calendar_helper.refresh_access_token(refresh_token)
    update_attributes(
      access_token:     resp["access_token"],
      token_expires_at: resp["expires_in"].to_i.seconds.from_now
    )
  end
end
