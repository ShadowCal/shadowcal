# frozen_string_literal: true

class SyncPairPerformSyncJob < Struct.new(:sync_pair_id)
  def perform
    pair = SyncPair.find(sync_pair_id)
    pair.perform_sync
  end

  def error(_job, exception)
    Rollbar.error(exception, error_details)
  end

  def error_details
    sync_pair = begin
      SyncPair.find(sync_pair_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    if sync_pair.nil?
      {
        sync_pair_id: sync_pair_id,
        sync_pair: nil,
      }
    else
      {
        sync_pair_id: sync_pair_id,
        sync_pair: sync_pair.as_json,
        from_calendar: sync_pair.from_calendar.try(:as_json),
        to_calendar: sync_pair.to_calendar.try(:as_json),
      }
    end
  end
end
