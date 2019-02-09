class AddAttendanceToEvent < ActiveRecord::Migration
  def change
    add_column :events, :is_attending, :boolean
  end
end
