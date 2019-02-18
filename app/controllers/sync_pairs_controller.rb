# frozen_string_literal: true

class SyncPairsController < ApplicationController
  before_action :authenticate_user!

  def create
    @sync_pair = current_user.sync_pairs.new params.require(:sync_pair).permit(:from_calendar_id, :to_calendar_id)

    if @sync_pair.save
      redirect_to :dashboard
    else
      new
      render action: :new
    end
  end

  def new
    @sync_pair ||= current_user.default_sync_pair
    @remote_accounts = current_user.remote_accounts
    @calendars_by_remote_account = CalendarAccountHelper.from_accounts_by_key(@remote_accounts)
  end

  def delete
    pair = SyncPair.find(params[:id])

    render nothing: true, status: :unauthorized if pair.user_id != current_user.id

    pair.destroy

    redirect_to :dashboard, success: "Will no longer cast that shadow."
  end

  def sync_now
    pair = SyncPair.find(params[:id])

    raise ActiveRecord::RecordNotFound if pair.nil?

    Delayed::Job.enqueue SyncPairPerformSyncJob.new(pair.id), queue: :cal_sync_pairs

    redirect_to :dashboard, notice: "Okay, queued to update!"
  end
end
