class AddWorkHoursToUser < ActiveRecord::Migration
  def change
    add_column :users, :work_hours_start_at, :time
    add_column :users, :work_hours_end_at, :time
  end
end
