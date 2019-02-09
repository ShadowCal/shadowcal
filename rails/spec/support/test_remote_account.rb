# frozen_string_literal: true

class TestRemoteAccount < RemoteAccount
  def self.calendar_helper
    TestCalendarApiHelper
  end

  def refresh_token!
    update_attributes(
      access_token:     '',
      token_expires_at: 10.minutes.from_now
    )
  end
end
