# frozen_string_literal: true

class RequestCalendarsJob < Struct.new(:google_account_id)
  def perform
    account = GoogleAccount.find(google_account_id)
    account.calendars = GoogleCalendarApiHelper.request_calendars(account.access_token)
    account.save!
  end

  def error(_job, exception)
    Rollbar.error(exception, error_details)
  end

  def error_details
    account = begin
      GoogleAccount.find(google_account_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    if account.nil?
      {
        google_account_id: google_account_id,
        google_account: nil,
      }
    else
      {
        google_account_id: google_account_id,
        google_account: account.as_json,
        user: account.user.try(:as_json),
        calendars: account.calendars.as_json,
      }
    end
  end
end
