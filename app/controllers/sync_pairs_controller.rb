class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  def create
    new_pair = current_user.sync_pairs.build params.require(:sync_pair).permit(:from_calendar_id, :to_calendar_id)

    new_pair.save

    redirect_to :dashboard
  end

  def new
    @google_accounts = current_user.google_accounts
    @calendars_by_google_account = CalendarAccountHelper.from_accounts_by_key(@google_accounts)
    @has_calendars = @google_accounts.all? {|acc| acc.calendars.any? }

    @new_sync_pair = SyncPair.new if @google_accounts.any? and @has_calendars
  end

  def sync_now
    pair = SyncPair.find(params[:id])

    raise ActiveRecord::RecordNotFound if pair.nil?

    pair.perform_sync

    redirect_to :dashboard
  end

end
