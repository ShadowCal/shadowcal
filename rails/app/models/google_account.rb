# frozen_string_literal: true

class GoogleAccount < RemoteAccount
  def self.calendar_helper
    CalendarApiHelper::Google
  end
end
