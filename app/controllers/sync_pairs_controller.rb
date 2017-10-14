class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  make_resourceful do
    actions :create
    belongs_to :user

    response_for :create do
      #current_object.cast_shadows! if current_object.persisted?
      redirect_to :dashboard
    end
  end

end
