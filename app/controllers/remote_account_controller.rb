# frozen_string_literal: true

class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  def delete
    redirect_to :dashboard, success: "Not yet implemented"
  end
end
