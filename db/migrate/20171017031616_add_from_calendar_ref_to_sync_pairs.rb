class AddFromCalendarRefToSyncPairs < ActiveRecord::Migration
  def change
    remove_column :sync_pairs, :from_cal_id, :string
    remove_column :sync_pairs, :from_google_account_id, :integer
    remove_column :sync_pairs, :to_cal_id, :string
    remove_column :sync_pairs, :to_google_account_id, :integer

    add_column :sync_pairs, :from_calendar_id, :integer
    add_foreign_key :sync_pairs, :calendars, column: :from_calendar_id

    add_column :sync_pairs, :to_calendar_id, :integer
    add_foreign_key :sync_pairs, :calendars, column: :to_calendar_id
  end
end
