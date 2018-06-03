# frozen_string_literal: true

class OutlookAccount < RemoteAccount
  def self.calendar_helper
    CalendarApiHelper::Outlook
  end
end
