# frozen_string_literal: true

class AddLastSyncAtToSyncPair < ActiveRecord::Migration
  def change
    add_column :sync_pairs, :last_synced_at, :datetime
  end
end
