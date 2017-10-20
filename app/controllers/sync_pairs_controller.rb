class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  def create
    new_pair = current_user.sync_pairs.build params.require(:sync_pair).permit(:from_calendar_id, :to_calendar_id)

    new_pair.save

    redirect_to :dashboard
  end

end
