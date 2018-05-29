# frozen_string_literal: true

class OutlookAccount < RemoteAccount
  def self.calendar_helper
    CalendarApiHelper::Outlook
  end

  def refresh_token!
    # resp = self.class.calendar_helper.refresh_access_token(refresh_token)
    # update_attributes(
    #   access_token:     resp[],
    #   token_expires_at: 40.minutes.from_now
    # )
  end
end
