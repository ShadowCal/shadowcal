class NilasController < ApplicationController
  before_action :authenticate_user!

  def connect
    callback_url = url_for(:action => 'callback')

    redirect_to nilas.url_for_authentication(callback_url, current_user.email, {trial: true})
  end

  def callback
    current_user.update_attributes! nilas_token: nilas.token_for_code(params[:code])
    redirect_to user_root_url
  end
end
