# frozen_string_literal: true

class RequestCalendarsJob < Struct.new(:remote_account_id)
  def perform
    account = RemoteAccount.find(remote_account_id)
    account.calendars = account.request_calendars
    account.save!
  end

  def error(_job, exception)
    Rollbar.error(exception, error_details)
  end

  def error_details
    account = begin
      RemoteAccount.find(remote_account_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    if account.nil?
      {
        remote_account_id: remote_account_id,
        remote_account: nil,
      }
    else
      {
        remote_account_id: remote_account_id,
        remote_account: account.as_json,
        user: account.user.try(:as_json),
        calendars: account.calendars.as_json,
      }
    end
  end
end
