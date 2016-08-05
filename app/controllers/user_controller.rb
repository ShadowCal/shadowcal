class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @calendars = calendars
  end
end
