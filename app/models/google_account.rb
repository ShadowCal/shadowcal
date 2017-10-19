class GoogleAccount < ActiveRecord::Base
  belongs_to :user
  has_many :calendars

  after_create :fetch_calendars

  private
  def fetch_calendars
    self.calendars = GoogleCalendarApiHelper.request_calendars(access_token)
  end
  handle_asynchronously :fetch_calendars
end
