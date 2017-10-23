class GoogleAccount < ActiveRecord::Base
  belongs_to :user
  has_many :calendars

  after_create :fetch_calendars

  after_initialize :refresh_token!, if: :should_refresh_token?

  scope :to_be_refreshed, -> { where(
    'token_expires_at IS NOT NULL AND ' +
    'refresh_token IS NOT NULL AND ' +
    ' token_expires_at < ?', Time.now
  ) }


  private
  def fetch_calendars
    self.calendars = GoogleCalendarApiHelper.request_calendars(access_token)
  end
  handle_asynchronously :fetch_calendars

  def refresh_token!
    resp = GoogleCalendarApiHelper.refresh_access_token(refresh_token)
    update_attributes(
      access_token: resp['access_token'],
      token_expires_at: Time.now + resp['expires_in'].to_i.seconds
    )
  end

  def should_refresh_token?
    token_expires_at < Time.now unless token_expires_at.nil? or refresh_token.blank?
  end
end
