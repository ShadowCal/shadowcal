class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    @nilasspace = nilas(current_user.nilas_token).namespaces.first
    @events     = @nilasspace.events
  end
end
