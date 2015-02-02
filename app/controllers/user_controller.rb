class UserController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    return redirect_to nilas_connect_url unless current_user.nilas_token

    @nilasspace = nilas(current_user.nilas_token).namespaces.first
    @events     = @nilasspace.events
  end
end
