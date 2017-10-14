class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  make_resourceful do
    actions :create
    belongs_to :user

    response_for :create do
      redirect_to :dashboard
    end
  end


end
