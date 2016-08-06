class GoogleAccount < ActiveRecord::Base
  belongs_to :user

  def calendars
    client = AccessToken.new access_token

    service = Google::Apis::CalendarV3::CalendarService.new

    service.authorization = client

    service.list_calendar_lists.items
  end
end
