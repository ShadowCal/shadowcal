class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def error(status, code, message)
    render :json => {:response_type => "ERROR", :response_code => code, :message => message}, :status => status
  end

  # Redirect the user to their game, if they have an active one.
  def nilas(token=nil)
    (!token and @nilas) ? @nilas : Inbox::API.new(ENV['NILAS_APP_ID'], ['NILAS_APP_SECRET'], token)
  end
end
