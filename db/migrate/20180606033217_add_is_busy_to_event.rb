class AddIsBusyToEvent < ActiveRecord::Migration
  def change
    add_column :events, :is_busy, :bool, default: false, null: false
  end
end
