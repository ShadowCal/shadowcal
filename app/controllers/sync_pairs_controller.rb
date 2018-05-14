# frozen_string_literal: true

class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  def create
    current_user.sync_pairs.create! params.require(:sync_pair).permit(:from_calendar_id, :to_calendar_id)

    redirect_to :dashboard
  end

  def new
    @remote_accounts = current_user.remote_accounts
    @calendars_by_remote_account = CalendarAccountHelper.from_accounts_by_key(@remote_accounts)
  end

  def sync_now
    pair = SyncPair.find(params[:id])

    raise ActiveRecord::RecordNotFound if pair.nil?

    Delayed::Job.enqueue SyncPairPerformSyncJob.new(pair.id), queue: :cal_sync_pairs

    redirect_to :dashboard, notice: "Okay, queued to update!"
  end
end
