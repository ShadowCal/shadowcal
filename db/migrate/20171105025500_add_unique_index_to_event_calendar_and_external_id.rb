class AddUniqueIndexToEventCalendarAndExternalId < ActiveRecord::Migration
  def change
    add_index :events, [:external_id, :calendar_id], unique: true
  end
end
