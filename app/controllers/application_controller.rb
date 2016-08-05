class AccessToken
  attr_reader :token
  def initialize(token)
    @token = token
  end

  def apply!(headers)
    headers['Authorization'] = "Bearer #{@token}"
  end
end

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def error(status, code, message)
    render :json => {:response_type => "ERROR", :response_code => code, :message => message}, :status => status
  end

  def calendars
    access_token = AccessToken.new current_user.try(:access_token)

    service = Google::Apis::CalendarV3::CalendarService.new

    service.authorization = access_token

    service.list_calendar_lists.items
  end
end
