class AddUniqueConstraintOnSyncPairFromCalendarId < ActiveRecord::Migration
  def change
  	add_index :sync_pairs, :from_calendar_id, :unique => true
  end
end
