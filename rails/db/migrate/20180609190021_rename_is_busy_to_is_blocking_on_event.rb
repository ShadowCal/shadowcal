class RenameIsBusyToIsBlockingOnEvent < ActiveRecord::Migration
  def change
    rename_column :events, :is_busy, :is_blocking
  end
end
