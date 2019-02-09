class AddIsBusyToEvent < ActiveRecord::Migration
  def change
    add_column :events, :is_busy, :boolean
  end
end
