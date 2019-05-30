class AddSchedulingCalendarIdToUser < ActiveRecord::Migration
  def change
    add_reference :users, :scheduling_calendar, references: :calendars, index: true, foreign_key: true
  end
end
