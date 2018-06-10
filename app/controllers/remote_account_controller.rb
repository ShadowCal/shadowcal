# frozen_string_literal: true

class RemoteAccountController < ApplicationController
  before_action :authenticate_user!

  def delete
    current_user.remote_accounts.where('id = ?', params[:id]).destroy_all

    redirect_to :dashboard
  end
end
