
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def error(status, code, message)
    render :json => {:response_type => "ERROR", :response_code => code, :message => message}, :status => status
  end
end
